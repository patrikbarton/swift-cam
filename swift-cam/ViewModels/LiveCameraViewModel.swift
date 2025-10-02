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
    @Published var isLoadingModel = false
    @Published var lowResPreviewImage: UIImage? = nil
    var showLowResPreview = false
    
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
        
        // Create a fresh request with our completion handler (even if cached, we need our handler)
        if let baseRequest = await modelService.createModel(for: modelType) { [weak self] request, error in
            self?.processLiveClassifications(for: request, error: error)
        } {
            // CRITICAL FIX: Recreate the request with our completion handler
            // Cached requests keep their old handlers, which breaks live detection
            let model = baseRequest.model
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processLiveClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            
            currentModel = modelType
            classificationRequest = request
            liveResults.removeAll()
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
    
    private func processLiveClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard error == nil, let observations = request.results as? [VNClassificationObservation] else { return }

            // Directly map the latest observations to results for instant feedback
            self.liveResults = observations.prefix(5).compactMap { observation -> ClassificationResult? in
                guard observation.confidence > 0.25 else { return nil }
                return ClassificationResult(identifier: observation.identifier, confidence: Double(observation.confidence))
            }
        }
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
        
        captureCompletion?(image)
        captureCompletion = nil
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

        // Low-res preview generation (GPU-accelerated with CoreImage)
        if showLowResPreview {
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
            let scaleX = modelInputSize.width / croppedCIImage.extent.width
            let scaleY = modelInputSize.height / croppedCIImage.extent.height
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

            let scaledImage = croppedCIImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let finalImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self.lowResPreviewImage = finalImage
                }
            }
        } else {
            if lowResPreviewImage != nil {
                DispatchQueue.main.async {
                    self.lowResPreviewImage = nil
                }
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
    }
}

