
//
//  LiveCameraViewModel.swift
//  swift-cam
//
//  ViewModel for live camera classification (Enhanced with Multi-Camera + Low-Res Preview)
//

import SwiftUI
import Combine
@preconcurrency import AVFoundation
import Vision
import CoreML
import CoreImage
import OSLog
import CoreLocation
import ImageIO
import UniformTypeIdentifiers


/// Manages the live camera feed and real-time ML classification with a simplified, efficient, and concurrency-safe architecture.
///
/// This ViewModel coordinates the entire live camera experience by delegating ML inference tasks
/// to the shared `VisionService`, which handles all model and request caching.
///
/// **Key Responsibilities:**
/// - Camera session management (multi-camera support).
/// - Throttling and dispatching camera frames to `VisionService` for analysis.
/// - Receiving classification results and updating the UI.
/// - Managing the "Best Shot" automatic capture sequence.
/// - Handling user-configurable features like face blurring and object highlighting.
///
/// **Concurrency Architecture:**
/// - The ViewModel is a `@MainActor` to safely publish changes to the UI.
/// - `AVCaptureSession` and related properties are marked `nonisolated` and are managed exclusively on a serial `processingQueue` to prevent data races.
/// - The `captureOutput` delegate method is `nonisolated` and uses a structured `Task` to bridge from the background queue to the async world.
/// - UI updates are explicitly dispatched back to the main actor via `await MainActor.run`.
@MainActor
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
    var bestShotConfidenceThreshold: Double = 0.8 // Default value, updated from view

    
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
    
    // These properties are accessed from the background processingQueue.
    // Marking them nonisolated tells the compiler they are not part of the MainActor's state.
    // We are responsible for ensuring thread-safe access, which we do via the serial `processingQueue`.
    nonisolated let session = AVCaptureSession()
    nonisolated private let photoOutput = AVCapturePhotoOutput()
    nonisolated private let videoOutput = AVCaptureVideoDataOutput()
    private let photoSaver = PhotoSaverService()
    
    // Throttling properties for performance management
    private var lastProcessingTime: Date = Date()
    private var lastBlurOverlayTime: Date = Date() // Separate timing for blur overlay
    private let processingInterval: TimeInterval = 0.5 // Run classification every 0.5s
    nonisolated private let processingQueue = DispatchQueue(label: "classification.queue", qos: .userInitiated)
    private let thumbnailQueue = DispatchQueue(label: "thumbnail.generation.queue", qos: .utility)
    
    // The ViewModel now only needs to know which model is currently active.
    // The VisionService handles all loading, caching, and request management.
    private var currentModel: MLModelType = .mobileNet
    
    private let visionService = VisionService.shared
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
        // Defer session setup to the background queue where it will be managed.
        processingQueue.async {
            self.setupSessionAndOutputs()
        }
        discoverDevicesAndSetInitialCamera()
    }
    
    /// Configures the AVCaptureSession and its inputs/outputs.
    /// This method is `nonisolated` because it only touches other `nonisolated` properties.
    /// It must be called from the `processingQueue`.
    nonisolated private func setupSessionAndOutputs() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

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
    }
    
    private func discoverDevicesAndSetInitialCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )

        // This updates UI properties, so it must be on the main thread.
        self.availableBackCameras = discoverySession.devices
        Logger.cameraSetup.log("📸 Discovered back cameras: \(self.availableBackCameras.map { $0.localizedName })")

        if let wideCamera = self.availableBackCameras.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            switchToDevice(wideCamera)
        } else if let firstAvailable = self.availableBackCameras.first {
            switchToDevice(firstAvailable)
        }
    }
    
    func switchToDevice(_ device: AVCaptureDevice) {
        // The work of switching the device must happen on the processing queue.
        processingQueue.async {
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }

            // Remove existing input
            if let currentInput = self.session.inputs.first {
                self.session.removeInput(currentInput)
            }

            guard let input = try? AVCaptureDeviceInput(device: device) else {
                Logger.cameraSetup.error("Could not create input for device \(device.localizedName).")
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                // Dispatch UI updates back to the main actor.
                Task { @MainActor in
                    self.activeCamera = device
                    Logger.cameraSetup.log("✅ Switched to camera: \(device.localizedName)")
                }
            } else {
                Logger.cameraSetup.error("Cannot add input for device \(device.localizedName).")
            }
        }
    }
    
    func switchCamera() {
        // Front/Back toggle logic remains on the MainActor
        let newPosition: AVCaptureDevice.Position = (activeCamera?.position == .back) ? .front : .back

        if newPosition == .front {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
            if let device = discoverySession.devices.first {
                switchToDevice(device)
            }
            self.availableBackCameras = []
        } else {
            discoverDevicesAndSetInitialCamera()
        }
    }
    
    /// Updates the active ML model for live classification.
    func updateModel(to modelType: MLModelType) {
        guard modelType != currentModel else { return }
        
        currentModel = modelType
        liveResults.removeAll()
        
        switch modelType {
        case .mobileNet, .resnet50:
            self.modelInputSize = CGSize(width: 224, height: 224)
        case .fastViT:
            self.modelInputSize = CGSize(width: 256, height: 256)
        }
    }

    // MARK: - Best Shot Sequence
    
    func startBestShotSequence(duration: Double) {
        guard !isBestShotSequenceActive else { return }
        
        hapticManager.impact(.medium)
        Logger.bestShot.info("Starting Best Shot sequence for \(duration)s")
        isBestShotSequenceActive = true
        bestShotCountdown = duration
        bestShotCandidates.removeAll()
        bestShotCandidateCount = 0
        
        sequenceTimer?.invalidate()
        sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.bestShotCountdown -= 1
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
        
        processBestShotCandidates()
    }
    
    private func processBestShotCandidates() {
        let sortedCandidates = bestShotCandidates.sorted { $0.result.confidence > $1.result.confidence }
        Logger.bestShot.info("Found \(self.bestShotCandidates.count) candidates. Presenting top \(sortedCandidates.count).")
        self.topCandidates = sortedCandidates
        self.bestShotCandidates.removeAll()
    }
    
    func startSession() {
        processingQueue.async { self.session.startRunning() }
        locationManager.startUpdatingLocation()
    }
    
    func stopSession() {
        processingQueue.async { self.session.stopRunning() }
        locationManager.stopUpdatingLocation()
        Task { @MainActor in
            self.liveResults.removeAll()
            self.lowResPreviewImage = nil
        }
    }
    
    func capturePhotoAndSave() {
        let settings = AVCapturePhotoSettings()
        // photoOutput is nonisolated, so we can call it from the MainActor
        // and its delegate methods will be called on the correct queue.
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
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
    
    private func processAndHighlight(results: [ClassificationResult]) {
        self.liveResults = results
        var highlight = false
        for result in results {
            let identifier = result.identifier.lowercased()
            let keysToCheck = [identifier] + identifier.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            for key in keysToCheck {
                if let threshold = self.highlightRules[key], result.confidence >= threshold {
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
    // This delegate method is called by AVFoundation on a background thread.
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), let originalImage = UIImage(data: imageData) else { return }
        
        let originalMetadata = photo.metadata
        
        Task {
            let processedImage = await applyFaceBlurIfNeeded(to: originalImage)
            
            let location = await MainActor.run { self.includeLocationMetadata ? self.currentLocation : nil }
            
            let finalImageData = createImageDataWithMetadata(
                image: processedImage,
                originalMetadata: originalMetadata as [String: Any],
                location: location
            )
            
            guard let finalImageData = finalImageData else {
                Logger.bestShot.error("Failed to create image data with metadata")
                return
            }
            
            let result = await MainActor.run { self.pendingBestShotResult }
            if let result = result {
                await MainActor.run { self.pendingBestShotResult = nil }
                
                thumbnailQueue.async {
                    let thumbnail = processedImage.preparingThumbnail(of: CGSize(width: 400, height: 400))
                    Task { @MainActor in
                        let candidate = CaptureCandidate(imageData: finalImageData, result: result, thumbnail: thumbnail, location: self.currentLocation)
                        self.bestShotCandidates.append(candidate)
                        self.bestShotCandidateCount += 1
                        self.hapticManager.impact(.light)
                        Logger.bestShot.info("Successfully captured hi-res candidate for \(result.identifier).")
                    }
                }
                return
            }
            
            await hapticManager.impact(.heavy)
            let locationToSave = await MainActor.run { self.includeLocationMetadata ? self.currentLocation : nil }
            photoSaver.saveImageData(finalImageData, location: locationToSave)
            
            await MainActor.run {
                self.showSaveConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showSaveConfirmation = false
                }
            }
        }
    }
    
    nonisolated private func createImageDataWithMetadata(image: UIImage, originalMetadata: [String: Any], location: CLLocation?) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        var metadata = originalMetadata
        if let location = location {
            metadata[kCGImagePropertyGPSDictionary as String] = location.gpsMetadata
        }
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

// MARK: - Camera Frame Processing
extension LiveCameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// The main entry point for processing live video frames. This method is called by AVFoundation on the `processingQueue`.
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Create a new Task to bridge from the synchronous, non-isolated delegate method into the world of Swift Concurrency.
        Task {
            // Immediately hop to the main actor to perform throttling checks against properties that are part of the main actor's state.
            let canProcess = await MainActor.run {
                let currentTime = Date()
                guard currentTime.timeIntervalSince(self.lastProcessingTime) >= self.processingInterval else { return false }
                guard !self.isProcessing else { return false }
                
                // Update state and proceed
                self.lastProcessingTime = currentTime
                self.isProcessing = true
                return true
            }
            
            // If throttling check passes, proceed with processing.
            if canProcess {
                // Ensure `isProcessing` is set back to false when the scope is exited.
                defer {
                    Task { @MainActor in self.isProcessing = false }
                }
                
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                
                // Determine camera orientation, requiring a brief hop to the main actor to read the `activeCamera` property.
                let orientation = await MainActor.run { self.activeCamera?.position == .front ? CGImagePropertyOrientation.rightMirrored : .right }
                let currentModel = await MainActor.run { self.currentModel }
                
                // --- Perform Classification ---
                Task.detached(priority: .userInitiated) {
                    do {
                        let results = try await self.visionService.performClassification(on: pixelBuffer, for: currentModel, orientation: orientation)
                        await MainActor.run {
                            self.processAndHighlight(results: results)
                        }
                    } catch {
                        Logger.model.warning("Vision request failed: \(error.localizedDescription)")
                    }
                }
                
                // --- UI Previews (Restored) ---
                Task.detached(priority: .utility) {
                    await self.updateUIPreviews(pixelBuffer: pixelBuffer, currentTime: Date())
                }
                
                // --- Best Shot Candidate Capture ---
                await MainActor.run { // Hop to main actor to safely read best shot properties
                    if self.isBestShotSequenceActive, !self.bestShotTargetLabel.isEmpty {
                        let now = Date()
                        guard now.timeIntervalSince(self.lastBestShotTime) > 1.0 else { return }

                        if let bestResult = self.liveResults.first(where: { $0.identifier.lowercased().contains(self.bestShotTargetLabel.lowercased()) }),
                           bestResult.confidence > self.bestShotConfidenceThreshold {
                            
                            Logger.bestShot.debug("High-confidence object found: \(bestResult.identifier). Triggering hi-res capture.")
                            self.pendingBestShotResult = bestResult
                            self.lastBestShotTime = now
                            self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
                        }
                    }
                }
            }
        }
    }
    
    /// Handles the logic for updating the low-resolution and face-blur preview images.
    private func updateUIPreviews(pixelBuffer: CVPixelBuffer, currentTime: Date) async {
        // Fetch all required properties from the main actor in one go.
        let (showLowRes, liveBlur, blurStyle, modelSize) = await MainActor.run { (self.showLowResPreview, self.livePreviewBlurEnabled, self.blurStyle, self.modelInputSize) }
        let isFrontCamera = await MainActor.run { self.activeCamera?.position == .front }

        if showLowRes {
            // Pass the required modelSize into the nonisolated function.
            if let lowResImage = createLowResPreview(from: pixelBuffer, isFrontCamera: isFrontCamera, modelSize: modelSize) {
                await MainActor.run { self.lowResPreviewImage = lowResImage }
            }
        } else {
            await MainActor.run { if self.lowResPreviewImage != nil { self.lowResPreviewImage = nil } }
        }
        
        if !showLowRes && liveBlur {
            let shouldUpdate = await MainActor.run {
                let shouldUpdate = currentTime.timeIntervalSince(self.lastBlurOverlayTime) >= 1.0
                if shouldUpdate {
                    self.lastBlurOverlayTime = currentTime
                }
                return shouldUpdate
            }
            
            if shouldUpdate {
                if let blurredImage = await createFaceBlurPreview(from: pixelBuffer, isFrontCamera: isFrontCamera, blurStyle: blurStyle) {
                    await MainActor.run { self.faceBlurOverlayImage = blurredImage }
                } else {
                    await MainActor.run { if self.faceBlurOverlayImage != nil { self.faceBlurOverlayImage = nil } }
                }
            }
        } else {
            await MainActor.run { if self.faceBlurOverlayImage != nil { self.faceBlurOverlayImage = nil } }
        }
    }
    
    /// Creates a low-resolution, center-cropped preview image suitable for display.
    nonisolated private func createLowResPreview(from pixelBuffer: CVPixelBuffer, isFrontCamera: Bool, modelSize: CGSize) -> UIImage? {
        let originalCIImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageExtent = originalCIImage.extent
        let shorterSide = min(imageExtent.width, imageExtent.height)
        let croppingRect = CGRect(
            x: (imageExtent.width - shorterSide) / 2.0,
            y: (imageExtent.height - shorterSide) / 2.0,
            width: shorterSide,
            height: shorterSide
        )
        let croppedCIImage = originalCIImage.cropped(to: croppingRect)
        
        // Use the modelSize passed in as a parameter instead of accessing the main actor property.
        let scaleX = modelSize.width / croppedCIImage.extent.width
        let scaleY = modelSize.height / croppedCIImage.extent.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let scaledImage = croppedCIImage.transformed(by: transform)
        
        guard let cgImage = self.context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        let orientation: UIImage.Orientation = isFrontCamera ? .leftMirrored : .right
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
    
    /// Creates a preview image with blurred faces.
    nonisolated private func createFaceBlurPreview(from pixelBuffer: CVPixelBuffer, isFrontCamera: Bool, blurStyle: BlurStyle) async -> UIImage? {
        do {
            guard let blurredCIImage = try await self.faceBlurService.blurFaces(in: pixelBuffer, blurRadius: 15.0, blurStyle: blurStyle) else { return nil }
            guard let cgImage = self.context.createCGImage(blurredCIImage, from: blurredCIImage.extent) else { return nil }
            
            let orientation: UIImage.Orientation = isFrontCamera ? .leftMirrored : .right
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        } catch {
            return nil
        }
    }
}

// Helper extension for GPS metadata
fileprivate extension CLLocation {
    var gpsMetadata: [String: Any] {
        var metadata: [String: Any] = [:]
        let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
        let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"
        
        metadata[kCGImagePropertyGPSLatitude as String] = abs(self.coordinate.latitude)
        metadata[kCGImagePropertyGPSLatitudeRef as String] = latitudeRef
        metadata[kCGImagePropertyGPSLongitude as String] = abs(self.coordinate.longitude)
        metadata[kCGImagePropertyGPSLongitudeRef as String] = longitudeRef
        metadata[kCGImagePropertyGPSAltitude as String] = abs(self.altitude)
        metadata[kCGImagePropertyGPSAltitudeRef as String] = self.altitude < 0 ? 1 : 0
        metadata[kCGImagePropertyGPSTimeStamp as String] = ISO8601DateFormatter().string(from: self.timestamp)
        
        return metadata
    }
}

