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
class ModelService {
    static let shared = ModelService()
    
    // Corrected: Cache the base MLModel, not the VNCoreMLModel wrapper.
    private var modelCache: [MLModelType: MLModel] = [:]
    private var labelCache: [MLModelType: [String]] = [:]
    private let modelQueue = DispatchQueue(label: "model.loading.queue", qos: .userInitiated)
    
    private init() {}
    
    func getLabels(for modelType: MLModelType) async throws -> [String] {
        // Check label cache first
        if let cachedLabels = labelCache[modelType] {
            return cachedLabels
        }
        
        // If labels not cached, load the MLModel and extract them
        let mlModel = try await loadCoreMLModel(for: modelType)
        
        // Corrected: This now works directly on the MLModel
        guard let labels = mlModel.modelDescription.classLabels as? [String] else {
            throw ModelLoadingError.labelsUnavailable
        }
        
        // Cache and return the labels
        self.labelCache[modelType] = labels
        return labels
    }
    
    // Renamed and made public: this is the primary function for VMs to get a model.
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
    
    // Renamed for clarity: this function handles the loading from disk and fallback logic
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
    
    /// Clear all cached models
    func clearCache() {
        modelCache.removeAll()
        labelCache.removeAll()
    }
}
