//
//  ModelLoadingError.swift
//  swift-cam
//
//  Error types for ML model loading
//

import Foundation

enum ModelLoadingError: LocalizedError {
    case modelNotFound(String)
    case neuralEngineFailure(String)
    case cpuFallbackFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let modelName):
            return "Model \(modelName) could not be found."
        case .neuralEngineFailure(let modelName):
            return "Neural Engine failed to load \(modelName)."
        case .cpuFallbackFailed(let modelName):
            return "CPU fallback failed for \(modelName)."
        }
    }
}

