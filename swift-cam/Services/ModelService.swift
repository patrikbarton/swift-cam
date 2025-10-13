//
//  ModelService.swift
//  swift-cam
//
//  Service for ML model loading, caching, and management
//

import CoreML
import Vision
import OSLog
import UIKit

/// Manages ML model loading, caching, and inference configuration
///
/// This singleton service handles all CoreML model operations:
/// - Loading models from disk (pre-compiled .mlmodelc bundles)
/// - In-memory caching for instant model switching
/// - Label extraction from model metadata
/// - Compute unit configuration and fallback
///
/// **Caching Strategy:**
/// Models are cached after first load, enabling instant switching between models.
/// The cache stores the base `MLModel`, not the Vision wrapper, for maximum flexibility.
///
/// **Thread Safety:**
/// Model loading operations are serialized on a dedicated background queue
/// to prevent race conditions while allowing concurrent access to cached models.
///
/// **Usage:**
/// ```swift
/// let service = ModelService.shared
/// let model = try await service.loadCoreMLModel(for: .mobileNet)
/// let labels = try await service.getLabels(for: .resnet50)
/// ```
class ModelService {
    static let shared = ModelService()
    
    // MARK: - Properties
    
    /// Cache of loaded ML models (base MLModel, not Vision wrapper)
    private var modelCache: [MLModelType: MLModel] = [:]
    
    /// Cache of model class labels for autocomplete
    private var labelCache: [MLModelType: [String]] = [:]
    
    /// Serial queue for thread-safe model loading
    private let modelQueue = DispatchQueue(label: "model.loading.queue", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Label Extraction
    
    /// Get class labels from a model's metadata
    ///
    /// Labels are cached after first extraction for performance.
    /// Used for autocomplete in Best Shot target selection.
    ///
    /// - Parameter modelType: The model to get labels from
    /// - Returns: Array of class label strings
    /// - Throws: ModelLoadingError if labels unavailable
    func getLabels(for modelType: MLModelType) async throws -> [String] {
        // Check label cache first
        if let cachedLabels = labelCache[modelType] {
            return cachedLabels
        }
        
        // If labels not cached, load the MLModel and extract them
        let mlModel = try await loadCoreMLModel(for: modelType)
        
        guard let labels = mlModel.modelDescription.classLabels as? [String] else {
            throw ModelLoadingError.labelsUnavailable
        }
        
        // Cache and return the labels
        self.labelCache[modelType] = labels
        return labels
    }
    
    // MARK: - Model Loading
    
    /// Load a CoreML model, using cache if available
    ///
    /// This is the primary method for loading models. It checks the cache first,
    /// and only loads from disk if the model hasn't been cached yet.
    ///
    /// **Performance:**
    /// - Cached: ~0.001s (instant)
    /// - First load: ~0.5-2s (depends on model size)
    ///
    /// - Parameter modelType: The model to load
    /// - Returns: The loaded MLModel
    /// - Throws: ModelLoadingError if model cannot be loaded
    func loadCoreMLModel(for modelType: MLModelType) async throws -> MLModel {
        // Check cache first
        if let cachedModel = modelCache[modelType] {
            ConditionalLogger.debug(Logger.model, "⚡ Using cached \(modelType.displayName) model object")
            return cachedModel
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            modelQueue.async {
                do {
                    // This now returns an MLModel
                    let model = try self.loadModelFromFile(for: modelType)
                    // Cache the MLModel
                    self.modelCache[modelType] = model
                    continuation.resume(returning: model)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Load model from disk with fallback logic
    ///
    /// Attempts to load model with Neural Engine acceleration first.
    /// Falls back to CPU for FastViT if Neural Engine fails.
    ///
    /// - Parameter modelType: Model to load
    /// - Returns: Loaded MLModel
    /// - Throws: ModelLoadingError on failure
    private func loadModelFromFile(for modelType: MLModelType) throws -> MLModel {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        
        do {
            // This now directly returns the MLModel
            return try self.getMLModel(for: modelType, configuration: configuration)
        } catch {
            Logger.model.warning("Failed to load \(modelType.displayName) with optimal settings, trying CPU fallback: \(error.localizedDescription)")
            // Fallback for FastViT on CPU
            if modelType == .fastViT {
                let cpuConfig = MLModelConfiguration()
                cpuConfig.computeUnits = .cpuOnly
                do {
                    return try self.getMLModel(for: modelType, configuration: cpuConfig)
                } catch let fallbackError {
                    Logger.model.error("CPU fallback for \(modelType.displayName) also failed: \(fallbackError.localizedDescription)")
                    throw fallbackError
                }
            }
            throw error
        }
    }

    /// Get the actual MLModel instance for a given type
    ///
    /// - Parameters:
    ///   - modelType: Type of model to instantiate
    ///   - configuration: ML configuration with compute unit settings
    /// - Returns: Instantiated MLModel
    /// - Throws: Error if model cannot be loaded
    private func getMLModel(for modelType: MLModelType, configuration: MLModelConfiguration) throws -> MLModel {
        switch modelType {
        case .mobileNet:
            return try MobileNetV2(configuration: configuration).model
        case .resnet50:
            return try Resnet50(configuration: configuration).model
        case .fastViT:
            return try FastViTMA36F16(configuration: configuration).model
        }
    }
    
    // MARK: - Compute Unit Detection
    
    /// Determine which compute unit is actually being used
    ///
    /// - Parameters:
    ///   - model: The loaded model
    ///   - configuration: The configuration used to load it
    /// - Returns: Human-readable compute unit string
    func determineActualComputeUnit(from model: MLModel, configuration: MLModelConfiguration) -> String {
        switch configuration.computeUnits {
        case .cpuOnly:
            return "CPU Only"
        case .cpuAndNeuralEngine:
            return "Neural Engine"
        case .cpuAndGPU:
            return "GPU"
        case .all:
            if isNeuralEngineAvailable() {
                return "Neural Engine"
            } else {
                return "GPU"
            }
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Check if Neural Engine is available on this device
    private func isNeuralEngineAvailable() -> Bool {
        // Neural Engine is available on A11+ chips (iPhone X and newer, 2017+)
        if #available(iOS 13.0, *) {
            return true // Most devices running iOS 13+ have Neural Engine
        }
        return false
    }
    
    /// Creates a test image for compute unit verification
    func createTestImage(size: CGSize, featureName: String) -> MLFeatureProvider {
        let renderer = UIGraphicsImageRenderer(size: size)
        let testUIImage = renderer.image { context in
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemGreen.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint.zero,
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])
        }
        
        guard let pixelBuffer = testUIImage.toCVPixelBuffer() else {
            fatalError("Could not create test pixel buffer for size \(size)")
        }
        
        do {
            return try MLDictionaryFeatureProvider(dictionary: [featureName: MLFeatureValue(pixelBuffer: pixelBuffer)])
        } catch {
            fatalError("Could not create feature provider with feature name '\(featureName)': \(error)")
        }
    }
    
    /// Clear all cached models (useful on memory warning)
    func clearCache() {
        modelCache.removeAll()
        labelCache.removeAll()
    }
}
