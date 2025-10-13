//
//  LiveCameraViewModel.swift
//  swift-cam
//
//  ViewModel for live camera classification (Enhanced with Multi-Camera + Low-Res Preview)
//

import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreML
import CoreImage
import OSLog
import CoreLocation
import ImageIO
import UniformTypeIdentifiers


/// Manages live camera feed and real-time ML classification
///
/// This ViewModel coordinates the entire live camera experience, including:
/// - Camera session management (multi-camera support)
/// - Real-time object detection using Vision framework
/// - Best Shot automatic capture sequence
/// - Object highlighting based on custom rules
/// - Assisted capture mode (only allow capture when target detected)
/// - Face blurring for privacy protection
///
/// **Threading Architecture:**
/// - Camera capture runs on background `processingQueue`
/// - ML inference throttled to 0.5s intervals for performance
/// - UI updates dispatched to main thread via `@MainActor`
///
/// **Usage:**
/// ```swift
/// @StateObject private var cameraVM = LiveCameraViewModel()
/// 
/// cameraVM.startSession()
/// cameraVM.updateModel(to: .mobileNet)
/// cameraVM.startBestShotSequence(duration: 10.0)
/// ```
class LiveCameraViewModel: NSObject, ObservableObject {
    @Published var liveResults: [ClassificationResult] = []
    @Published var isProcessing = false
    @Published var shouldHighlight = false
    var highlightRules: [String: Double] = [:]
    @Published var isLoadingModel = false
    @Published var lowResPreviewImage: UIImage? = nil
    @Published var faceBlurOverlayImage: UIImage? = nil // Blurred preview for normal camera mode
    @Published var showSaveConfirmation = false
    var showLowResPreview = false
    var faceBlurringEnabled = false // Blur faces in saved photos
    var livePreviewBlurEnabled = false // Show blur overlay on live preview (performance intensive)
    var includeLocationMetadata = true // Setting to control location embedding
    var blurStyle: BlurStyle = .gaussian
    var bestShotTargetLabel: String = ""
    
    // Best Shot Properties
    @Published var isBestShotSequenceActive = false
    @Published var bestShotCountdown: Double = 0
    @Published var bestShotCandidateCount: Int = 0
    @Published var topCandidates: [CaptureCandidate] = []
    private var bestShotCandidates: [CaptureCandidate] = []
    private var sequenceTimer: Timer?
    private var pendingBestShotResult: ClassificationResult? = nil
    private var lastBestShotTime: Date = .distantPast

    struct CaptureCandidate: Equatable, Identifiable {
        let id = UUID()
        let imageData: Data
        let result: ClassificationResult
        var thumbnail: UIImage? // For fast UI previews
        var location: CLLocation? = nil
        
        static func == (lhs: LiveCameraViewModel.CaptureCandidate, rhs: LiveCameraViewModel.CaptureCandidate) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    @Published var availableBackCameras: [AVCaptureDevice] = []
    @Published var activeCamera: AVCaptureDevice?
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private let photoSaver = PhotoSaverService()
    
    // Enhanced object tracking properties
    private var lastProcessingTime: Date = Date()
    private var lastBlurOverlayTime: Date = Date() // Separate timing for blur overlay
    private let processingInterval: TimeInterval = 0.5 // Reduced frequency for better performance
    private var processingQueue = DispatchQueue(label: "classification.queue", qos: .userInitiated)
    private let thumbnailQueue = DispatchQueue(label: "thumbnail.generation.queue", qos: .utility)
    
    private var currentModel: MLModelType = .mobileNet
    private var classificationRequest: VNCoreMLRequest?
    private let modelService = ModelService.shared
    private let faceBlurService = FaceBlurringService()
    private let hapticManager = HapticManagerService.shared
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation? = nil
    
    // For low-res preview generation
    private var modelInputSize: CGSize = CGSize(width: 224, height: 224)
    private let context = CIContext()
    
    override init() {
        super.init()
        locationManager.delegate = self
        setupSessionAndOutputs()
        discoverDevicesAndSetInitialCamera()
        Task { @MainActor in
            await loadModel(.mobileNet)
        }
    }
    
    private func setupSessionAndOutputs() {
        session.beginConfiguration()

        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }
    
    private func discoverDevicesAndSetInitialCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )

        DispatchQueue.main.async {
            self.availableBackCameras = discoverySession.devices
            Logger.cameraSetup.log("📸 Discovered back cameras: \(self.availableBackCameras.map { $0.localizedName })")

            if let wideCamera = self.availableBackCameras.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
                self.switchToDevice(wideCamera)
            } else if let firstAvailable = self.availableBackCameras.first {
                self.switchToDevice(firstAvailable)
            }
        }
    }
    
    func switchToDevice(_ device: AVCaptureDevice) {
        processingQueue.async {
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }

            if let currentInput = self.session.inputs.first {
                self.session.removeInput(currentInput)
            }

            guard let input = try? AVCaptureDeviceInput(device: device) else {
                Logger.cameraSetup.error("Could not create input for device \(device.localizedName).")
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                DispatchQueue.main.async {
                    self.activeCamera = device
                    Logger.cameraSetup.log("✅ Switched to camera: \(device.localizedName)")
                }
            } else {
                Logger.cameraSetup.error("Cannot add input for device \(device.localizedName).")
            }
        }
    }
    
    func switchCamera() {
        // Front/Back toggle
        let newPosition: AVCaptureDevice.Position = (activeCamera?.position == .back) ? .front : .back

        if newPosition == .front {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
            if let device = discoverySession.devices.first {
                switchToDevice(device)
            }
            DispatchQueue.main.async { self.availableBackCameras = [] }
        } else {
            discoverDevicesAndSetInitialCamera()
        }
    }
    
    @MainActor
    func loadModel(_ modelType: MLModelType) async {
        isLoadingModel = true
        liveResults.removeAll()

        do {
            // 1. Load the MLModel from the service
            let mlModel = try await modelService.loadCoreMLModel(for: modelType)
            
            // 2. Create the VNCoreMLModel wrapper
            let visionModel = try VNCoreMLModel(for: mlModel)
            
            // 3. Create the request with the completion handler
            // Fixed: Use Task with @MainActor to avoid nested dispatch and retain cycles
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard let self = self else { return }
                Task { @MainActor in
                    self.processLiveClassifications(for: request, error: error)
                }
            }
            request.imageCropAndScaleOption = .centerCrop
            
            self.classificationRequest = request
            self.currentModel = modelType
            
        } catch {
            Logger.model.error("❌ Failed to load model \(modelType.displayName) in LiveCameraViewModel: \(error.localizedDescription)")
            // Optionally, set an error state for the UI
        }
        
        // Set the input size for the low-res preview
        switch modelType {
        case .mobileNet, .resnet50:
            self.modelInputSize = CGSize(width: 224, height: 224)
        case .fastViT:
            self.modelInputSize = CGSize(width: 256, height: 256)
        }
        
        isLoadingModel = false
    }
    
    func updateModel(to modelType: MLModelType) {
        guard modelType != currentModel else { return }
        
        Task { @MainActor in
            await loadModel(modelType)
        }
    }

    // MARK: - Best Shot Sequence
    
    /// Start Best Shot automatic capture sequence
    /// 
    /// Monitors live camera feed for the target object and automatically captures
    /// high-resolution photos when detected with >80% confidence. Captures are
    /// throttled to one per second to avoid duplicates.
    ///
    /// - Parameter duration: Length of capture sequence in seconds
    func startBestShotSequence(duration: Double) {
        guard !isBestShotSequenceActive else { return }
        
        hapticManager.impact(.medium)
        Logger.bestShot.info("Starting Best Shot sequence for \(duration)s")
        isBestShotSequenceActive = true
        bestShotCountdown = duration
        bestShotCandidates.removeAll()
        bestShotCandidateCount = 0
        
        // Invalidate any existing timer
        sequenceTimer?.invalidate()
        
        // Start a new timer
        sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.bestShotCountdown -= 1
                
                // Add haptic feedback for the last 3 seconds
                if self.bestShotCountdown <= 3 && self.bestShotCountdown > 0 {
                    self.hapticManager.impact(.medium)
                }

                if self.bestShotCountdown <= 0 {
                    self.stopBestShotSequence()
                }
            }
        }
    }
    
    func stopBestShotSequence() {
        guard isBestShotSequenceActive else { return }
        
        hapticManager.generate(.success)
        Logger.bestShot.info("Finished Best Shot sequence.")
        isBestShotSequenceActive = false
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        
        // Process results
        processBestShotCandidates()
    }
    
    private func processBestShotCandidates() {
        // Sort candidates by confidence
        let sortedCandidates = bestShotCandidates.sorted { $0.result.confidence > $1.result.confidence }
        
        Logger.bestShot.info("Found \(self.bestShotCandidates.count) candidates. Presenting top \(sortedCandidates.count).")
        
        // Publish the top candidates to the UI
        self.topCandidates = sortedCandidates
        self.bestShotCandidates.removeAll()
    }
    
    func startSession() {
        processingQueue.async { self.session.startRunning() }
        locationManager.startUpdatingLocation()
    }
    
    func stopSession() {
        session.stopRunning()
        locationManager.stopUpdatingLocation()
        DispatchQueue.main.async {
            self.liveResults.removeAll()
            self.lowResPreviewImage = nil
        }
    }
    
    func capturePhotoAndSave() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    /// Apply face blurring to captured photo
    private func applyFaceBlurIfNeeded(to image: UIImage) async -> UIImage {
        guard faceBlurringEnabled else { return image }
        
        do {
            let blurred = try await faceBlurService.blurFaces(in: image, blurRadius: 20.0, blurStyle: blurStyle)
            Logger.bestShot.info("🔒 Face blurring applied to live capture")
            return blurred
        } catch {
            Logger.bestShot.warning("⚠️ Face blurring failed on live capture: \(error.localizedDescription)")
            return image
        }
    }
    
    private func processLiveClassifications(for request: VNRequest, error: Error?) {
        guard error == nil, let observations = request.results as? [VNClassificationObservation] else { return }

        // Directly map the latest observations to results for instant feedback
        self.liveResults = observations.prefix(5).compactMap { observation -> ClassificationResult? in
            guard observation.confidence > 0.25 else { return nil }
            return ClassificationResult(identifier: observation.identifier, confidence: Double(observation.confidence))
        }
        
        // Check for highlight condition
        var highlight = false
        for result in self.liveResults {
            let identifier = result.identifier.lowercased()
            // Check primary label and potential synonyms/broader categories
            let keysToCheck = [identifier] + identifier.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            
            for key in keysToCheck {
                if let threshold = highlightRules[key], result.confidence >= threshold {
                    highlight = true
                    break
                }
            }
            if highlight { break }
        }
        self.shouldHighlight = highlight
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - CLLocationManagerDelegate
extension LiveCameraViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.bestShot.error("Location manager failed with error: \(error.localizedDescription)")
    }
}

// MARK: - Camera Delegate Extensions
extension LiveCameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let originalImage = UIImage(data: imageData) else { return }
        
        // Extract original metadata from photo
        let originalMetadata = photo.metadata as [String: Any]
        
        // Apply face blurring if enabled (for both manual and best shot captures)
        Task {
            let processedImage = await applyFaceBlurIfNeeded(to: originalImage)
            
            // Preserve EXIF metadata when creating final image data
            let finalImageData = createImageDataWithMetadata(
                image: processedImage,
                originalMetadata: originalMetadata,
                location: includeLocationMetadata ? currentLocation : nil
            )
            
            guard let finalImageData = finalImageData else {
                Logger.bestShot.error("Failed to create image data with metadata")
                return
            }
            
            // Check if this is a "Best Shot" capture
            if let result = pendingBestShotResult {
                self.pendingBestShotResult = nil // Reset immediately
                
                // Create a thumbnail in the background to avoid blocking the main thread
                thumbnailQueue.async {
                    let thumbnail = processedImage.preparingThumbnail(of: CGSize(width: 400, height: 400))
                    
                    // Add the candidate on the main thread
                    DispatchQueue.main.async {
                        let candidate = CaptureCandidate(imageData: finalImageData, result: result, thumbnail: thumbnail, location: self.currentLocation)
                        self.bestShotCandidates.append(candidate)
                        self.bestShotCandidateCount += 1
                        self.hapticManager.impact(.light)
                        Logger.bestShot.info("Successfully captured hi-res candidate for \(result.identifier).")
                    }
                }
                return // End here for best shot captures
            }
            
            // If not a best shot capture, it's a manual capture. Save it directly.
            hapticManager.impact(.heavy)
            
            // Save photo with optional location (metadata already embedded)
            let locationToSave = includeLocationMetadata ? currentLocation : nil
            photoSaver.saveImageData(finalImageData, location: locationToSave)
            
            // Trigger confirmation UI
            DispatchQueue.main.async {
                self.showSaveConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showSaveConfirmation = false
                }
            }
        }
    }
    
    /// Creates JPEG data from UIImage while preserving EXIF metadata
    ///
    /// - Parameters:
    ///   - image: The processed UIImage to save
    ///   - originalMetadata: Original EXIF metadata from AVCapturePhoto
    ///   - location: Optional GPS location to embed
    /// - Returns: JPEG data with preserved metadata
    private func createImageDataWithMetadata(
        image: UIImage,
        originalMetadata: [String: Any],
        location: CLLocation?
    ) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Create mutable metadata dictionary
        var metadata = originalMetadata
        
        // Add GPS metadata if location provided
        if let location = location {
            var gpsMetadata: [String: Any] = [:]
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            gpsMetadata[kCGImagePropertyGPSLatitude as String] = abs(latitude)
            gpsMetadata[kCGImagePropertyGPSLatitudeRef as String] = latitude >= 0 ? "N" : "S"
            gpsMetadata[kCGImagePropertyGPSLongitude as String] = abs(longitude)
            gpsMetadata[kCGImagePropertyGPSLongitudeRef as String] = longitude >= 0 ? "E" : "W"
            
            if location.altitude >= 0 {
                gpsMetadata[kCGImagePropertyGPSAltitude as String] = location.altitude
                gpsMetadata[kCGImagePropertyGPSAltitudeRef as String] = 0
            }
            
            if location.horizontalAccuracy >= 0 {
                gpsMetadata[kCGImagePropertyGPSHPositioningError as String] = location.horizontalAccuracy
            }
            
            // Add timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy:MM:dd"
            gpsMetadata[kCGImagePropertyGPSDateStamp as String] = dateFormatter.string(from: location.timestamp)
            
            dateFormatter.dateFormat = "HH:mm:ss"
            gpsMetadata[kCGImagePropertyGPSTimeStamp as String] = dateFormatter.string(from: location.timestamp)
            
            metadata[kCGImagePropertyGPSDictionary as String] = gpsMetadata
        }
        
        // Create output data
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        // Add image with metadata
        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        
        // Finalize
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }
}

extension LiveCameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        
        guard !isProcessing else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Determine proper orientation based on camera position
        // Camera sensor provides landscape data, we need to rotate for portrait display
        let isFrontCamera = activeCamera?.position == .front
        
        if showLowResPreview {
            processingQueue.async {
                let originalCIImage = CIImage(cvPixelBuffer: pixelBuffer)
                
                // Don't apply any orientation here - keep raw sensor data
                // The Image view will handle the display orientation
                
                // Crop to center square first (matching .centerCrop behavior)
                let imageExtent = originalCIImage.extent
                let shorterSide = min(imageExtent.width, imageExtent.height)
                let croppingRect = CGRect(
                    x: (imageExtent.width - shorterSide) / 2.0,
                    y: (imageExtent.height - shorterSide) / 2.0,
                    width: shorterSide,
                    height: shorterSide
                )
                let croppedCIImage = originalCIImage.cropped(to: croppingRect)
                
                // Scale down to model input size
                let scaleX = self.modelInputSize.width / croppedCIImage.extent.width
                let scaleY = self.modelInputSize.height / croppedCIImage.extent.height
                let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                
                let scaledImage = croppedCIImage.transformed(by: transform)
                
                // Apply face blurring to low-res preview if live preview blur enabled
                if self.livePreviewBlurEnabled {
                    Task {
                        var finalImageToDisplay = scaledImage
                        do {
                            if let blurredImage = try await self.faceBlurService.blurFaces(in: pixelBuffer, blurRadius: 10.0, blurStyle: self.blurStyle) {
                                // Scale the blurred image to preview size
                                let blurredExtent = blurredImage.extent
                                let inputWidth = await self.modelInputSize.width
                                let inputHeight = await self.modelInputSize.height
                                let blurScale = min(
                                    inputWidth / blurredExtent.width,
                                    inputHeight / blurredExtent.height
                                )
                                let blurTransform = CGAffineTransform(scaleX: blurScale, y: blurScale)
                                finalImageToDisplay = blurredImage.transformed(by: blurTransform)
                            }
                        } catch {
                            // Silently continue with unblurred preview
                        }
                        
                        if let cgImage = self.context.createCGImage(finalImageToDisplay, from: finalImageToDisplay.extent) {
                            // Create UIImage with proper orientation for display
                            // Portrait mode requires 90° rotation from landscape sensor data
                            let orientation: UIImage.Orientation = isFrontCamera ? .leftMirrored : .right
                            let finalImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                            DispatchQueue.main.async {
                                self.lowResPreviewImage = finalImage
                            }
                        }
                    }
                } else {
                    if let cgImage = self.context.createCGImage(scaledImage, from: scaledImage.extent) {
                        // Create UIImage with proper orientation for display
                        let orientation: UIImage.Orientation = isFrontCamera ? .leftMirrored : .right
                        let finalImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                        DispatchQueue.main.async {
                            self.lowResPreviewImage = finalImage
                        }
                    }
                }
            }
        } else if lowResPreviewImage != nil {
            DispatchQueue.main.async {
                self.lowResPreviewImage = nil
            }
        }
        
        // Handle face blur overlay for normal camera view (not low-res preview)
        if !showLowResPreview && livePreviewBlurEnabled {
            // Update blur overlay less frequently (every 1 second) using separate timer
            let shouldUpdateBlur = currentTime.timeIntervalSince(lastBlurOverlayTime) >= 1.0
            if shouldUpdateBlur {
                lastBlurOverlayTime = currentTime
                processingQueue.async {
                    Task {
                        do {
                            // Create a lower resolution preview for blur overlay
                            if let blurredImage = try await self.faceBlurService.blurFaces(in: pixelBuffer, blurRadius: 15.0, blurStyle: self.blurStyle) {
                                // Convert to UIImage with proper orientation
                                if let cgImage = self.context.createCGImage(blurredImage, from: blurredImage.extent) {
                                    let orientation: UIImage.Orientation = isFrontCamera ? .leftMirrored : .right
                                    let finalImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                                    DispatchQueue.main.async {
                                        self.faceBlurOverlayImage = finalImage
                                    }
                                }
                            }
                        } catch {
                            // Clear overlay if blur fails
                            DispatchQueue.main.async {
                                self.faceBlurOverlayImage = nil
                            }
                        }
                    }
                }
            }
        } else if faceBlurOverlayImage != nil {
            DispatchQueue.main.async {
                self.faceBlurOverlayImage = nil
            }
        }
        
        guard let classificationRequest = classificationRequest else { return }
        
        lastProcessingTime = currentTime
        
        // Pass correct orientation to the model request handler
        // For Vision framework, we need CGImagePropertyOrientation (not UIImage.Orientation)
        let visionOrientation: CGImagePropertyOrientation = isFrontCamera ? .rightMirrored : .right
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: visionOrientation)
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            // Silently handle errors to avoid UI disruption
        }
        
        // --- Best Shot Candidate Capture ---
        if isBestShotSequenceActive, !bestShotTargetLabel.isEmpty {
            let now = Date()
            // Throttle captures to once per second
            guard now.timeIntervalSince(lastBestShotTime) > 1.0 else { return }

            // Check if the top result matches the specific target label
            if let bestResult = liveResults.first(where: { $0.identifier.lowercased().contains(bestShotTargetLabel.lowercased()) }),
               bestResult.confidence > 0.8 {
                
                Logger.bestShot.debug("High-confidence object found: \(bestResult.identifier). Triggering hi-res capture.")
                self.pendingBestShotResult = bestResult
                self.lastBestShotTime = now
                self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
        }
    }
}
