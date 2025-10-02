//
//  LiveCameraViewModel.swift
//  swift-cam
//
//  ViewModel for live camera classification
//

import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreML
import OSLog

/// Manages live camera feed and real-time classification
class LiveCameraViewModel: NSObject, ObservableObject {
    @Published var liveResults: [ClassificationResult] = []
    @Published var isProcessing = false
    @Published var isLoadingModel = false
    
    private let cameraService = CameraService()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    // Enhanced object tracking properties
    private var lastProcessingTime: Date = Date()
    private let processingInterval: TimeInterval = 0.3
    private var processingQueue = DispatchQueue(label: "classification.queue", qos: .userInitiated)
    
    // Object accumulation for multiple detections
    private var detectedObjects: [String: ClassificationResult] = [:]
    private var objectExpiryTime: TimeInterval = 3.0
    private var lastCleanupTime: Date = Date()
    
    private var currentModel: MLModelType = .mobileNet
    private var classificationRequest: VNCoreMLRequest?
    private let modelService = ModelService.shared
    
    var session: AVCaptureSession {
        cameraService.session
    }
    
    override init() {
        super.init()
        cameraService.setupSession(delegate: self, queue: processingQueue)
        Task { @MainActor in
            await loadModel(.mobileNet)
        }
    }
    
    @MainActor
    func loadModel(_ modelType: MLModelType) async {
        isLoadingModel = true
        
        if let request = await modelService.createModel(for: modelType) { [weak self] request, error in
            self?.processLiveClassifications(for: request, error: error)
        } {
            currentModel = modelType
            classificationRequest = request
            detectedObjects.removeAll()
            liveResults.removeAll()
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
        cameraService.startSession(on: processingQueue)
    }
    
    func stopSession() {
        cameraService.stopSession()
        DispatchQueue.main.async {
            self.detectedObjects.removeAll()
            self.liveResults.removeAll()
        }
    }
    
    private func processLiveClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard error == nil,
                  let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            
            let currentTime = Date()
            
            let newResults = observations.prefix(5).compactMap { observation -> ClassificationResult? in
                guard observation.confidence > 0.25 else { return nil }
                return ClassificationResult(
                    identifier: observation.identifier,
                    confidence: Double(observation.confidence),
                    detectedAt: currentTime
                )
            }
            
            for result in newResults {
                let key = result.displayName.lowercased()
                
                if let existing = self.detectedObjects[key] {
                    if result.confidence > existing.confidence {
                        self.detectedObjects[key] = result
                    }
                } else {
                    self.detectedObjects[key] = result
                }
            }
            
            if currentTime.timeIntervalSince(self.lastCleanupTime) >= 1.0 {
                self.cleanupExpiredObjects(currentTime: currentTime)
                self.lastCleanupTime = currentTime
            }
            
            self.liveResults = Array(self.detectedObjects.values)
                .sorted { $0.confidence > $1.confidence }
                .prefix(6)
                .map { $0 }
        }
    }
    
    private func cleanupExpiredObjects(currentTime: Date) {
        detectedObjects = detectedObjects.filter { _, result in
            currentTime.timeIntervalSince(result.detectedAt) < objectExpiryTime
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
        
        guard let classificationRequest = classificationRequest else { return }
        
        lastProcessingTime = currentTime
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            // Silently handle errors to avoid UI disruption
        }
    }
}

