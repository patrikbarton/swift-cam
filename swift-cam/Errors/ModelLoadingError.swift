//
//  ModelLoadingError.swift
//  swift-cam
//
//  Error types for ML model loading
//

import Foundation

enum ModelLoadingError: Error, LocalizedError {
    case failedToLoad(String)
    case labelsUnavailable
    
    var errorDescription: String? {
        switch self {
        case .failedToLoad(let modelName):
            return "Failed to load the \(modelName) model."
        case .labelsUnavailable:
            return "Could not retrieve class labels from the model."
        }
    }
}
