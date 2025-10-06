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
    
    // Cache loaded models to avoid reloading
    private var modelCache: [MLModelType: VNCoreMLRequest] = [:]
    private let modelQueue = DispatchQueue(label: "model.loading.queue", qos: .userInitiated)
    
    private init() {}
    
    func createModel(for modelType: MLModelType) async throws -> VNCoreMLRequest {
        if let cachedRequest = modelCache[modelType] {
            Logger.model.debug("⚡ Using cached \(modelType.displayName)")
            return cachedRequest
        }

        let configurations: [MLModelConfiguration] = {
            var configs = [MLModelConfiguration()] // Default .all
            if modelType == .fastViT {
                let cpuConfig = MLModelConfiguration()
                cpuConfig.computeUnits = .cpuOnly
                configs.append(cpuConfig)
            }
            return configs
        }()

        for config in configurations {
            do {
                let coreMLModel = try await loadCoreMLModel(for: modelType, config: config)
                let model = try VNCoreMLModel(for: coreMLModel)
                let request = VNCoreMLRequest(model: model)
                request.imageCropAndScaleOption = .centerCrop
                
                modelCache[modelType] = request
                Logger.model.info("✅ Loaded \(modelType.displayName) with \(config.computeUnits.description)")
                return request
            } catch {
                Logger.model.warning("⚠️ Failed to load \(modelType.displayName) with \(config.computeUnits.description): \(error.localizedDescription)")
            }
        }

        throw ModelLoadingError.failedToLoad(modelType.displayName)
    }

    private func loadCoreMLModel(for modelType: MLModelType, config: MLModelConfiguration) async throws -> MLModel {
        switch modelType {
        case .mobileNet:
            return try MobileNetV2(configuration: config).model
        case .resnet50:
            return try Resnet50(configuration: config).model
        case .fastViT:
            return try FastViTMA36F16(configuration: config).model
        }
    }
    
    /// Determines the actual compute unit being used
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
    }
}

extension MLComputeUnits {
    var description: String {
        switch self {
        case .all: return "All"
        case .cpuOnly: return "CPU Only"
        case .cpuAndGPU: return "CPU & GPU"
        case .cpuAndNeuralEngine: return "CPU & Neural Engine"
        @unknown default: return "Unknown"
        }
    }
}

