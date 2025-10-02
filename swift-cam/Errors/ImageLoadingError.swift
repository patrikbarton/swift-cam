//
//  ImageLoadingError.swift
//  swift-cam
//
//  Error types for image loading
//

import Foundation

enum ImageLoadingError: LocalizedError {
    case unsupportedFormat
    case corruptedData
    case accessDenied
    case cloudSyncError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Image format not supported. Please try JPEG, PNG, or HEIC."
        case .corruptedData:
            return "The selected image appears to be corrupted."
        case .accessDenied:
            return "Unable to access the selected image."
        case .cloudSyncError:
            return "Cloud Photo Library sync error. Please try a different image."
        }
    }
}

