//
//  FaceBlurError.swift
//  swift-cam
//
//  Error types for Face Blurring
//

import Foundation

/// Errors that can occur during face blurring
enum FaceBlurError: Error, LocalizedError {
    case invalidImage
    case processingFailed
    case noFacesDetected
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .processingFailed:
            return "Failed to process image"
        case .noFacesDetected:
            return "No faces detected"
        }
    }
}
