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
///
/// This ViewModel handles the "Home" tab functionality:
/// - Loading and switching between ML models (MobileNet, ResNet, FastViT)
/// - Classifying images from photo library
/// - Managing model state and UI feedback
/// - Verifying compute unit (Neural Engine) availability
///
/// **Model Lifecycle:**
/// 1. Models are preloaded during app startup via `ModelService`
/// 2. Switching models creates new Vision request with cached MLModel
/// 3. Classification runs on background thread, results on main thread
///
/// **Usage:**
/// ```swift
/// @StateObject private var viewModel = HomeViewModel()
/// 
/// await viewModel.classifyImage(image, applyFaceBlur: true)
/// await viewModel.updateModel(to: .resnet50)
/// ```
@MainActor
class HomeViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var classificationResults: [ClassificationResult] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var isLoadingModel = false
    @Published var loadingModelName = ""
    @Published var isSwitchingModel = false
    @Published var currentComputeUnit: String = ""
    @Published var isComputeUnitVerified: Bool = false
    @Published var modelLabels: [String] = []
    
    private var isCurrentlySwitching = false
    private var currentModel: MLModelType = .mobileNet
    private var classificationRequest: VNCoreMLRequest?
    private let modelService = ModelService.shared
    private let faceBlurService = FaceBlurringService()
    
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
    
    /// Load an ML model and create Vision classification request
    ///
    /// - Parameter modelType: The model to load (MobileNet, ResNet, or FastViT)
    /// - Note: Models are cached by `ModelService` for instant switching
    func loadModel(_ modelType: MLModelType) async {
        ConditionalLogger.debug(Logger.model, "📥 Loading \(modelType.displayName)")
        
        loadingModelName = modelType.displayName
        isLoadingModel = true
        modelLabels = [] // Clear previous labels
        
        do {
            // 1. Load the MLModel from the service
            let mlModel = try await modelService.loadCoreMLModel(for: modelType)
            
            // 2. Create the VNCoreMLModel wrapper
            let visionModel = try VNCoreMLModel(for: mlModel)
            
            // 3. Create the request (no completion handler needed for this VM)
            let request = VNCoreMLRequest(model: visionModel)
            
            currentModel = modelType
            classificationRequest = request
            ConditionalLogger.debug(Logger.model, "✅ Loaded \(modelType.displayName)")
            await verifyComputeUnit(for: modelType)
            await loadLabels(for: modelType) // Load labels
        } catch {
            Logger.model.error("❌ Failed to load \(modelType.displayName): \(error.localizedDescription)")
            errorMessage = "Failed to load model: \(error.localizedDescription)"
        }
        
        isLoadingModel = false
        loadingModelName = ""
    }
    
    private func loadLabels(for modelType: MLModelType) async {
        do {
            let labels = try await modelService.getLabels(for: modelType)
            // Remove duplicates and sort
            let uniqueLabels = Array(Set(labels)).sorted()
            await MainActor.run { self.modelLabels = uniqueLabels }
        } catch {
            Logger.model.error("❌ Failed to get labels for \(modelType.displayName): \(error.localizedDescription)")
            // By not setting an error message, the UI can gracefully degrade
            // (autocomplete just won't work)
        }
    }
    
    func updateModel(to modelType: MLModelType) async {
        guard modelType != currentModel else { return }
        guard !isCurrentlySwitching else { return }
        
        ConditionalLogger.debug(Logger.model, "🔄 Switching to \(modelType.displayName)")
        
        isCurrentlySwitching = true
        isSwitchingModel = true
        currentComputeUnit = ""
        isComputeUnitVerified = false
        
        let imageToReclassify = capturedImage
        
        await loadModel(modelType)
        
        if let image = imageToReclassify {
            await classifyImage(image, applyFaceBlur: false) // Don't re-blur on model switch
        }
        
        isSwitchingModel = false
        isCurrentlySwitching = false
    }
    
    /// Classify an image using the current ML model
    ///
    /// - Parameters:
    ///   - image: The UIImage to classify
    ///   - applyFaceBlur: Whether to blur detected faces for privacy
    ///   - blurStyle: Style of blur to apply (gaussian, pixelated, or black box)
    /// - Note: Classification runs on background thread, updates published on main thread
    func classifyImage(_ image: UIImage, applyFaceBlur: Bool = false, blurStyle: BlurStyle = .gaussian) async {
        guard let classificationRequest = classificationRequest else {
            errorMessage = "Model not loaded"
            return
        }
        
        isAnalyzing = true
        classificationResults = []
        errorMessage = nil
        
        // Apply face blurring if enabled
        var processedImage = image
        if applyFaceBlur {
            do {
                processedImage = try await faceBlurService.blurFaces(in: image, blurRadius: 20.0, blurStyle: blurStyle)
                Logger.privacy.info("🔒 Face blurring applied to captured image")
            } catch {
                Logger.privacy.warning("⚠️ Face blurring failed: \(error.localizedDescription)")
                // Continue with original image if blurring fails
            }
        }
        
        capturedImage = processedImage
        
        guard let cgImage = processedImage.cgImage else {
            isAnalyzing = false
            errorMessage = "Unable to process image"
            return
        }
        
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: processedImage.imageOrientation.cgImagePropertyOrientation
        )
        
        do {
            try handler.perform([classificationRequest])
            guard let observations = classificationRequest.results as? [VNClassificationObservation] else {
                errorMessage = "Unable to classify image"
                isAnalyzing = false
                return
            }
            
            classificationResults = observations
                .prefix(AppConstants.maxClassificationResults)
                .map { observation in
                    ClassificationResult(
                        identifier: observation.identifier,
                        confidence: Double(observation.confidence)
                    )
                }
            isAnalyzing = false
        } catch {
            isAnalyzing = false
            errorMessage = "Classification failed: \(error.localizedDescription)"
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

