//
//  VisionService.swift
//  swift-cam
//
//  Service for Vision framework operations and ML inference
//

import Vision
import CoreML
import OSLog

/// Manages Vision framework operations and ML inference
///
/// This service eliminates code duplication between ViewModels by providing
/// a centralized place for Vision-related operations:
/// - Creating Vision classification requests
/// - Managing ML model lifecycle
/// - Handling inference results
///
/// **Usage:**
/// ```swift
/// let service = VisionService.shared
/// let request = try await service.createClassificationRequest(for: .mobileNet) { results in
///     // Handle results
/// }
/// ```
class VisionService {
    
    static let shared = VisionService()
    
    private let modelService = ModelService.shared
    
    private init() {}
    
    // MARK: - Request Creation
    
    /// Create a Vision classification request for the specified model
    ///
    /// - Parameters:
    ///   - modelType: The ML model to use
    ///   - completion: Completion handler for classification results
    /// - Returns: Configured VNCoreMLRequest ready for inference
    /// - Throws: ModelLoadingError if model cannot be loaded
    func createClassificationRequest(
        for modelType: MLModelType,
        completion: @escaping ([ClassificationResult]) -> Void
    ) async throws -> VNCoreMLRequest {
        
        // Load the ML model from cache or disk
        let mlModel = try await modelService.loadCoreMLModel(for: modelType)
        
        // Create Vision model wrapper
        let visionModel = try VNCoreMLModel(for: mlModel)
        
        // Create request with completion handler
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.model.error("Vision request failed: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let results = self.processClassificationResults(request)
            completion(results)
        }
        
        // Configure request for optimal performance
        request.imageCropAndScaleOption = .centerCrop
        
        Logger.model.debug("Created Vision request for \(modelType.displayName)")
        return request
    }
    
    /// Create a synchronous Vision classification request (no completion handler)
    ///
    /// Useful when you want to handle results manually in the perform() call
    ///
    /// - Parameter modelType: The ML model to use
    /// - Returns: Configured VNCoreMLRequest
    /// - Throws: ModelLoadingError if model cannot be loaded
    func createSynchronousRequest(for modelType: MLModelType) async throws -> VNCoreMLRequest {
        let mlModel = try await modelService.loadCoreMLModel(for: modelType)
        let visionModel = try VNCoreMLModel(for: mlModel)
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .centerCrop
        return request
    }
    
    // MARK: - Result Processing
    
    /// Process Vision classification results into our app's model
    ///
    /// - Parameter request: The completed Vision request
    /// - Returns: Array of ClassificationResult sorted by confidence
    func processClassificationResults(_ request: VNRequest) -> [ClassificationResult] {
        guard let observations = request.results as? [VNClassificationObservation] else {
            Logger.model.warning("No classification observations found in request")
            return []
        }
        
        // Filter by minimum confidence and convert to our model
        let results = observations
            .filter { $0.confidence > 0.25 }
            .prefix(AppConstants.maxClassificationResults)
            .map { observation in
                ClassificationResult(
                    identifier: observation.identifier,
                    confidence: Double(observation.confidence)
                )
            }
        
        return Array(results)
    }
    
    /// Extract top N results from Vision observations
    ///
    /// - Parameters:
    ///   - observations: Raw Vision observations
    ///   - topN: Number of top results to return
    ///   - minimumConfidence: Minimum confidence threshold (default: 0.25)
    /// - Returns: Top classification results
    func extractTopResults(
        from observations: [VNClassificationObservation],
        topN: Int = 5,
        minimumConfidence: Float = 0.25
    ) -> [ClassificationResult] {
        return observations
            .filter { $0.confidence > minimumConfidence }
            .prefix(topN)
            .map { ClassificationResult(identifier: $0.identifier, confidence: Double($0.confidence)) }
    }
    
    // MARK: - Model Information
    
    /// Get the input size required for a model
    ///
    /// - Parameter modelType: The model to query
    /// - Returns: Expected input size (width, height)
    func getInputSize(for modelType: MLModelType) -> CGSize {
        switch modelType {
        case .mobileNet, .resnet50:
            return CGSize(width: 224, height: 224)
        case .fastViT:
            return CGSize(width: 256, height: 256)
        }
    }
}
