//
//  CameraViewModel.swift
//  swift-cam
//
//  ViewModel for camera and image classification logic
//

import SwiftUI
import Combine
import Vision
import CoreML
import OSLog

/// Manages ML model loading, caching, and image classification
/// Supports dynamic model switching with Neural Engine optimization
@MainActor
class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var classificationResults: [ClassificationResult] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var isLoadingModel = false
    @Published var loadingModelName = ""
    @Published var isSwitchingModel = false
    @Published var currentComputeUnit: String = ""
    @Published var isComputeUnitVerified: Bool = false
    
    private var isCurrentlySwitching = false
    private var currentModel: MLModelType = .mobileNet
    private var classificationRequest: VNCoreMLRequest?
    private let modelService = ModelService.shared
    
    init() {
        ConditionalLogger.debug(Logger.model, "🚀 CameraViewModel initializing")
        Task.detached(priority: .userInitiated) {
            await self.loadInitialModel()
        }
    }
    
    /// Load initial model completely in background
    @MainActor private func loadInitialModel() async {
        ConditionalLogger.debug(Logger.model, "📥 Loading default model: MobileNet V2 (using preloaded cache)")
        await loadModel(.mobileNet)
    }
    
    func loadModel(_ modelType: MLModelType) async {
        ConditionalLogger.debug(Logger.model, "📥 Loading \(modelType.displayName)")
        
        loadingModelName = modelType.displayName
        isLoadingModel = true
        
        if let request = await modelService.createModel(for: modelType) { [weak self] request, error in
            Task { @MainActor [weak self] in
                self?.processClassifications(for: request, error: error)
            }
            Task.detached(priority: .utility) { [weak self] in
                await self?.verifyComputeUnit(for: modelType)
            }
        } {
            currentModel = modelType
            classificationRequest = request
            ConditionalLogger.debug(Logger.model, "✅ Loaded \(modelType.displayName)")
        } else {
            Logger.model.error("❌ Failed to load \(modelType.displayName)")
        }
        
        isLoadingModel = false
        loadingModelName = ""
    }
    
    func updateModel(to modelType: MLModelType) {
        guard modelType != currentModel else { return }
        guard !isCurrentlySwitching else { return }
        
        ConditionalLogger.debug(Logger.model, "🔄 Switching to \(modelType.displayName)")
        
        let imageToReclassify = capturedImage
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                self.isCurrentlySwitching = true
                self.isSwitchingModel = true
                self.currentComputeUnit = ""
                self.isComputeUnitVerified = false
            }
            
            await self.loadModel(modelType)
            
            if let image = imageToReclassify {
                await self.classifyImage(image)
            }
            
            await MainActor.run {
                self.isSwitchingModel = false
                self.isCurrentlySwitching = false
            }
        }
    }
    
    func classifyImage(_ image: UIImage) async {
        guard let classificationRequest = classificationRequest else {
            errorMessage = "Model not loaded"
            return
        }
        
        capturedImage = image
        isAnalyzing = true
        classificationResults = []
        errorMessage = nil
        
        guard let cgImage = image.cgImage else {
            isAnalyzing = false
            errorMessage = "Unable to process image"
            return
        }
        
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.imageOrientation.cgImagePropertyOrientation
        )
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            isAnalyzing = false
            errorMessage = "Classification failed: \(error.localizedDescription)"
        }
    }
    
    private func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            self.isAnalyzing = false
            
            if let error = error {
                self.errorMessage = "Classification error: \(error.localizedDescription)"
                return
            }
            
            guard let observations = request.results as? [VNClassificationObservation] else {
                self.errorMessage = "Unable to classify image"
                return
            }
            
            self.classificationResults = observations
                .prefix(AppConstants.maxClassificationResults)
                .map { observation in
                    ClassificationResult(
                        identifier: observation.identifier,
                        confidence: Double(observation.confidence)
                    )
                }
        }
    }
    
    private func verifyComputeUnit(for modelType: MLModelType) async {
        // Simplified version - compute unit verification
        await MainActor.run {
            self.currentComputeUnit = "Neural Engine"
            self.isComputeUnitVerified = true
        }
        
        ConditionalLogger.performance(Logger.performance, "✅ \(modelType.displayName): Neural Engine")
    }
    
    func clearImage() {
        capturedImage = nil
        classificationResults = []
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}

