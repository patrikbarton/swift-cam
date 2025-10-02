//
//  ModelLoadingError.swift
//  swift-cam
//
//  Error types for ML model loading
//

import Foundation

enum ModelLoadingError: Error {
    case failedToLoad(String)
}
