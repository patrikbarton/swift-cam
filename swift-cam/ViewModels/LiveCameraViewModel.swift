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


/// Manages live camera feed and real-time classification with multi-camera support
class LiveCameraViewModel: NSObject, ObservableObject {
    @Published var liveResults: [ClassificationResult] = []
    @Published var isProcessing = false
    @Published var shouldHighlight = false
    var highlightRules: [String: Double] = [:]
    @Published var isLoadingModel = false
    @Published var lowResPreviewImage: UIImage? = nil
    var showLowResPreview = false
    var faceBlurringEnabled = false
    var blurStyle: BlurStyle = .gaussian
    var bestShotTargetLabel: String = ""
    
    // Best Shot Properties
    @Published var isBestShotSequenceActive = false
    @Published var bestShotCountdown: Double = 0
    @Published var topCandidates: [CaptureCandidate] = []
    private var bestShotCandidates: [CaptureCandidate] = []
    private var sequenceTimer: Timer?

    struct CaptureCandidate: Equatable, Identifiable {
        let id = UUID()
        let image: UIImage
        let result: ClassificationResult
        
        static func == (lhs: LiveCameraViewModel.CaptureCandidate, rhs: LiveCameraViewModel.CaptureCandidate) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    @Published var availableBackCameras: [AVCaptureDevice] = []
    @Published var activeCamera: AVCaptureDevice?
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    // Enhanced object tracking properties
    private var lastProcessingTime: Date = Date()
    private let processingInterval: TimeInterval = 0.5 // Reduced frequency for better performance
    private var processingQueue = DispatchQueue(label: "classification.queue", qos: .userInitiated)
    
    private var currentModel: MLModelType = .mobileNet
    private var classificationRequest: VNCoreMLRequest?
    private let modelService = ModelService.shared
    private let faceBlurService = FaceBlurringService()
    
    // For low-res preview generation
    private var modelInputSize: CGSize = CGSize(width: 224, height: 224)
    private let context = CIContext()
    
    override init() {
        super.init()
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
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                DispatchQueue.main.async {
                    self?.processLiveClassifications(for: request, error: error)
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
    
    func startBestShotSequence(duration: Double) {
        guard !isBestShotSequenceActive else { return }
        
        Logger.bestShot.info("Starting Best Shot sequence for \(duration)s")
        isBestShotSequenceActive = true
        bestShotCountdown = duration
        bestShotCandidates.removeAll()
        
        // Invalidate any existing timer
        sequenceTimer?.invalidate()
        
        // Start a new timer
        sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.bestShotCountdown -= 1
                if self.bestShotCountdown <= 0 {
                    self.stopBestShotSequence()
                }
            }
        }
    }
    
    private func stopBestShotSequence() {
        guard isBestShotSequenceActive else { return }
        
        Logger.bestShot.info("Finished Best Shot sequence.")
        isBestShotSequenceActive = false
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        
        // Process results
        processBestShotCandidates()
    }
    
    private func processBestShotCandidates() {
        // Sort candidates by confidence and take the top 3
        let top = Array(bestShotCandidates.sorted { $0.result.confidence > $1.result.confidence }.prefix(3))
        
        Logger.bestShot.info("Found \(self.bestShotCandidates.count) candidates. Presenting top \(top.count).")
        
        // Publish the top candidates to the UI
        self.topCandidates = top
        self.bestShotCandidates.removeAll()
    }
    
    func startSession() {
        processingQueue.async { self.session.startRunning() }
    }
    
    func stopSession() {
        session.stopRunning()
        DispatchQueue.main.async {
            self.liveResults.removeAll()
            self.lowResPreviewImage = nil
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    /// Apply face blurring to captured photo
    private func applyFaceBlurIfNeeded(to image: UIImage) async -> UIImage {
        guard faceBlurringEnabled else { return image }
        
        do {
            let blurred = try await faceBlurService.blurFaces(in: image, blurRadius: 20.0, blurStyle: blurStyle)
            Logger.privacy.info("🔒 Face blurring applied to live capture")
            return blurred
        } catch {
            Logger.privacy.warning("⚠️ Face blurring failed on live capture: \(error.localizedDescription)")
            return image
        }
    }
    
    @MainActor
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
}

// MARK: - Camera Delegate Extensions
extension LiveCameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            captureCompletion?(nil)
            return
        }
        
        // Apply face blurring if enabled before returning
        Task {
            let processedImage = await applyFaceBlurIfNeeded(to: image)
            captureCompletion?(processedImage)
            captureCompletion = nil
        }
    }
}

extension LiveCameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        
        guard !isProcessing else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // KEY CHANGE: Use .right orientation for portrait mode (matches actual device orientation)
        let imageOrientation = CGImagePropertyOrientation.right
        
        if showLowResPreview {
            processingQueue.async {
                let originalCIImage = CIImage(cvPixelBuffer: pixelBuffer)
                let rotatedCIImage = originalCIImage.oriented(imageOrientation)
                
                // Crop to center square first (matching .centerCrop behavior)
                let imageExtent = rotatedCIImage.extent
                let shorterSide = min(imageExtent.width, imageExtent.height)
                let croppingRect = CGRect(
                    x: (imageExtent.width - shorterSide) / 2.0,
                    y: (imageExtent.height - shorterSide) / 2.0,
                    width: shorterSide,
                    height: shorterSide
                )
                let croppedCIImage = rotatedCIImage.cropped(to: croppingRect)
                
                // Scale down to model input size
                let scaleX = self.modelInputSize.width / croppedCIImage.extent.width
                let scaleY = self.modelInputSize.height / croppedCIImage.extent.height
                let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                
                let scaledImage = croppedCIImage.transformed(by: transform)
                
                // Apply face blurring to preview if enabled
                if self.faceBlurringEnabled {
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
                            let finalImage = UIImage(cgImage: cgImage)
                            DispatchQueue.main.async {
                                self.lowResPreviewImage = finalImage
                            }
                        }
                    }
                } else {
                    if let cgImage = self.context.createCGImage(scaledImage, from: scaledImage.extent) {
                        let finalImage = UIImage(cgImage: cgImage)
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
        
        guard let classificationRequest = classificationRequest else { return }
        
        lastProcessingTime = currentTime
        
        // KEY CHANGE: Pass correct orientation to the model request handler
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: imageOrientation)
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            // Silently handle errors to avoid UI disruption
        }
        
        // --- Best Shot Candidate Capture ---
        if isBestShotSequenceActive, !bestShotTargetLabel.isEmpty {
            // Check if the top result matches the specific target label
            if let bestResult = liveResults.first(where: { $0.identifier.lowercased().contains(bestShotTargetLabel.lowercased()) }),
               bestResult.confidence > 0.8 {
                
                if let image = UIImage(sampleBuffer: sampleBuffer, orientation: .right) {
                    let candidate = CaptureCandidate(image: image, result: bestResult)
                    bestShotCandidates.append(candidate)
                    Logger.bestShot.debug("Adding best shot candidate: \(bestResult.identifier) @ \(bestResult.confidence)")
                }
            }
        }
    }
}
