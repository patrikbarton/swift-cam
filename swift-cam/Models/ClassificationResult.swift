//
//  ClassificationResult.swift
//  swift-cam
//
//  Data model for ML classification results
//

import SwiftUI

/// Represents a single classification result from ML inference
///
/// Contains the identified class, confidence score, and timestamp.
/// Provides computed properties for UI display including:
/// - Display name formatting (removes ImageNet prefixes)
/// - Confidence-based color coding
/// - Time-based opacity for fade effects
///
/// **Usage:**
/// ```swift
/// let result = ClassificationResult(
///     identifier: "n02084071 dog",
///     confidence: 0.95
/// )
/// Text(result.displayName)  // "Dog"
///     .foregroundColor(result.confidenceColor)  // Green for high confidence
/// ```
struct ClassificationResult: Equatable {
    
    // MARK: - Properties
    
    /// Raw identifier from ML model (may include ImageNet prefix)
    let identifier: String
    
    /// Confidence score (0.0 to 1.0)
    let confidence: Double
    
    /// When this result was detected
    let detectedAt: Date
    
    // MARK: - Initialization
    
    init(identifier: String, confidence: Double, detectedAt: Date = Date()) {
        self.identifier = identifier
        self.confidence = confidence
        self.detectedAt = detectedAt
    }
    
    // MARK: - Computed Properties
    
    /// User-friendly display name (removes ImageNet prefixes like "n02084071")
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
    
    /// Opacity based on time since detection (fades over 3 seconds)
    ///
    /// Used for live camera results that fade out as they age
    var opacity: Double {
        let timeSinceDetection = Date().timeIntervalSince(detectedAt)
        let maxTime: Double = 3.0
        return max(0.3, 1.0 - (timeSinceDetection / maxTime))
    }
    
    /// Color based on confidence level (SwiftUI)
    ///
    /// - Green: 50-100% confidence
    /// - Yellow: 35-50% confidence
    /// - Orange: 20-35% confidence
    /// - Red: Below 20% confidence
    var confidenceColor: Color {
        switch confidence {
        case 0.5...1.0: return .green
        case 0.35...0.5: return .yellow
        case 0.2...0.35: return .orange
        default: return .red
        }
    }
    
    /// Color based on confidence level (UIKit)
    ///
    /// UIKit version of confidenceColor for use in UIKit contexts
    var confidenceUIColor: UIColor {
        switch confidence {
        case 0.5...1.0: return UIColor.systemGreen
        case 0.35...0.5: return UIColor.systemYellow
        case 0.2...0.35: return UIColor.systemOrange
        default: return UIColor.systemRed
        }
    }
}

