//
//  ClassificationResult.swift
//  swift-cam
//
//  Data model for classification results
//

import SwiftUI
import Vision

struct ClassificationResult {
    let identifier: String
    let confidence: Double
    let detectedAt: Date
    
    init(identifier: String, confidence: Double, detectedAt: Date = Date()) {
        self.identifier = identifier
        self.confidence = confidence
        self.detectedAt = detectedAt
    }
    
    ///   - observations: The array of `VNClassificationObservation` from a Vision request.
    ///   - maxResults: The maximum number of results to return.
    ///   - minConfidence: The minimum confidence score for a result to be included.
    /// - Returns: An array of `ClassificationResult`.
    static func from(observations: [VNClassificationObservation], maxResults: Int, minConfidence: Float = 0.0) -> [ClassificationResult] {
        return observations
            .prefix(maxResults)
            .compactMap { observation in
                guard observation.confidence >= minConfidence else {
                    return nil
                }
                return ClassificationResult(
                    identifier: observation.identifier,
                    confidence: Double(observation.confidence)
                )
            }
    }
    
    var displayName: String {
        let components = identifier.components(separatedBy: " ")
        if components.count > 1 {
            let first = components[0]
            if first.count > 5 && first.hasPrefix("n") {
                return components.dropFirst().joined(separator: " ").capitalized
            }
        }
        return identifier.capitalized
    }
    
    var opacity: Double {
        let timeSinceDetection = Date().timeIntervalSince(detectedAt)
        let maxTime: Double = 3.0
        return max(0.3, 1.0 - (timeSinceDetection / maxTime))
    }
    
    var confidenceColor: Color {
        switch confidence {
        case 0.5...1.0: return .green
        case 0.35...0.5: return .yellow
        case 0.2...0.35: return .orange
        default: return .red
        }
    }
    
    var confidenceUIColor: UIColor {
        switch confidence {
        case 0.5...1.0: return UIColor.systemGreen
        case 0.35...0.5: return UIColor.systemYellow
        case 0.2...0.35: return UIColor.systemOrange
        default: return UIColor.systemRed
        }
    }
}
