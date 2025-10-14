//
//  VisionService.swift
//  swift-cam
//
//  Service for Vision framework operations and ML inference
//

import Vision
import CoreML
import OSLog
import UIKit

/// Manages Vision framework operations and ML inference using a modern, efficient, and reusable architecture.
///
/// This service centralizes all Vision-related operations, ensuring that expensive objects like
/// `VNCoreMLModel` and `VNCoreMLRequest` are created only once and reused across the app.
/// This prevents performance issues related to constant setup and teardown of the ML pipeline,
/// such as the `ANE_PowerOn` and `ANE_PowerOff` kernel events.
///
/// **Key Responsibilities:**
/// - Caching both `VNCoreMLModel` and `VNCoreMLRequest` objects.
/// - Providing a single, simple async method (`performClassification`) to run inference on an image.
/// - Pre-warming models at startup to ensure a responsive user experience.
actor VisionService {
    
    static let shared = VisionService()
    
    private let modelService = ModelService.shared
    
    // Caches for both the compiled model and the request object.
    // Caching the request is critical to prevent re-creation and hardware power cycling.
    private var visionModelCache: [MLModelType: VNCoreMLModel] = [:]
    private var requestCache: [MLModelType: VNCoreMLRequest] = [:]
    
    private init() {}
    
    // MARK: - Public API

    /// Performs image classification on a given pixel buffer using the specified model.
    ///
    /// This is the primary entry point for all classification tasks. It encapsulates the entire
    /// Vision pipeline: retrieving a cached model and request, creating an image handler,
    /// performing the request, and processing the results.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The `CVPixelBuffer` from the camera feed to be analyzed.
    ///   - modelType: The `MLModelType` to use for inference.
    ///   - orientation: The `CGImagePropertyOrientation` of the buffer to ensure correct rotation.
    /// - Returns: An array of `ClassificationResult` objects, sorted by confidence.
    /// - Throws: An error if the model fails to load or the request fails.
    func performClassification(
        on pixelBuffer: CVPixelBuffer,
        for modelType: MLModelType,
        orientation: CGImagePropertyOrientation
    ) async throws -> [ClassificationResult] {
        
        let classificationRequest = try await getClassificationRequest(for: modelType)
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        
        // Perform the request synchronously on the current async task.
        // This is the modern approach and avoids complex completion handlers.
        try handler.perform([classificationRequest])
        
        // Process and return the results directly.
        return processClassificationResults(from: classificationRequest)
    }

    // MARK: - Pre-warming

    /// Pre-warms all ML models by creating and caching their `VNCoreMLModel` and `VNCoreMLRequest` representations.
    /// This pays the one-time setup cost at startup, ensuring the first user interaction is instant.
    func prewarmAllModels() async {
        Logger.model.info("🔥 Starting Vision model pre-warming.")
        await withTaskGroup(of: Void.self) { group in
            for modelType in MLModelType.allCases {
                group.addTask {
                    do {
                        // Pre-warming now includes creating the request as well.
                        _ = try await self.getClassificationRequest(for: modelType)
                        Logger.model.info("✅ Vision model and request for \(modelType.displayName, privacy: .public) are pre-warmed.")
                    } catch {
                        Logger.model.error("❌ Failed to pre-warm Vision model for \(modelType.displayName, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
        }
        Logger.model.info("✅ All Vision models are pre-warmed and ready.")
    }
    
    // MARK: - Private Helpers

    /// Retrieves a cached `VNCoreMLRequest` or creates and caches a new one.
    private func getClassificationRequest(for modelType: MLModelType) async throws -> VNCoreMLRequest {
        if let cachedRequest = requestCache[modelType] {
            return cachedRequest
        }
        
        let visionModel = try await getVisionModel(for: modelType)
        
        // Create the request ONCE, without a completion handler.
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .centerCrop
        
        // Cache the request for future use.
        requestCache[modelType] = request
        Logger.model.info("✅ Created and cached VNCoreMLRequest for \(modelType.displayName, privacy: .public)")
        
        return request
    }

    /// Retrieves a cached `VNCoreMLModel` or creates and caches a new one.
    private func getVisionModel(for modelType: MLModelType) async throws -> VNCoreMLModel {
        if let cachedModel = visionModelCache[modelType] {
            Logger.model.debug("⚡ Using cached VNCoreMLModel for \(modelType.displayName, privacy: .public)")
            return cachedModel
        }

        let mlModel = try await modelService.loadCoreMLModel(for: modelType)
        let visionModel = try VNCoreMLModel(for: mlModel)
        
        visionModelCache[modelType] = visionModel
        Logger.model.info("✅ Created and cached VNCoreMLModel for \(modelType.displayName, privacy: .public)")
        
        return visionModel
    }
    
    /// Processes the results from a `VNRequest` into an array of `ClassificationResult`.
    private func processClassificationResults(from request: VNRequest) -> [ClassificationResult] {
        guard let observations = request.results as? [VNClassificationObservation] else {
            Logger.model.warning("No classification observations found in request")
            return []
        }
        
        return observations
            .filter { $0.confidence > 0.25 }
            .prefix(AppConstants.maxClassificationResults)
            .map { observation in
                ClassificationResult(
                    identifier: observation.identifier,
                    confidence: Double(observation.confidence)
                )
            }
    }
}
