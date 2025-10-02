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
    
    /// Creates a VNCoreMLRequest for the specified model type
    func createModel(
        for modelType: MLModelType,
        completion: @escaping (VNRequest, Error?) -> Void
    ) async -> VNCoreMLRequest? {
        // Check cache first
        if let cachedRequest = modelCache[modelType] {
            ConditionalLogger.debug(Logger.model, "⚡ Using cached \(modelType.displayName)")
            return cachedRequest
        }
        
        return await withCheckedContinuation { continuation in
            modelQueue.async {
                // First try with Neural Engine/GPU (optimal performance)
                let optimalConfiguration = MLModelConfiguration()
                optimalConfiguration.computeUnits = .all
                
                do {
                    let coreMLModel: MLModel
                    
                    switch modelType {
                    case .mobileNet:
                        coreMLModel = try MobileNetV2(configuration: optimalConfiguration).model
                    case .resnet50:
                        coreMLModel = try Resnet50(configuration: optimalConfiguration).model
                    case .fastViT:
                        coreMLModel = try FastViTMA36F16(configuration: optimalConfiguration).model
                    }
                    
                    let model = try VNCoreMLModel(for: coreMLModel)
                    let request = VNCoreMLRequest(model: model, completionHandler: completion)
                    request.imageCropAndScaleOption = .centerCrop
                    
                    // Cache the request
                    self.modelCache[modelType] = request
                    
                    continuation.resume(returning: request)
                    return
                } catch {
                    Logger.model.warning("Failed to load \(modelType.displayName) with Neural Engine/GPU, trying CPU fallback: \(error.localizedDescription)")
                }
                
                // Fallback: Try CPU-only for problematic models
                if modelType == .fastViT {
                    Logger.model.info("Trying \(modelType.displayName) with CPU fallback")
                    let cpuConfiguration = MLModelConfiguration()
                    cpuConfiguration.computeUnits = .cpuOnly
                    
                    do {
                        let coreMLModel = try FastViTMA36F16(configuration: cpuConfiguration).model
                        let model = try VNCoreMLModel(for: coreMLModel)
                        let request = VNCoreMLRequest(model: model, completionHandler: completion)
                        request.imageCropAndScaleOption = .centerCrop
                        
                        // Cache the request
                        self.modelCache[modelType] = request
                        
                        continuation.resume(returning: request)
                        return
                    } catch {
                        Logger.model.error("Failed to load \(modelType.displayName) even with CPU fallback: \(error.localizedDescription)")
                    }
                }
                
                // Complete failure
                continuation.resume(returning: nil)
            }
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

