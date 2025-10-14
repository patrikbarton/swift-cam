//
//  Logger+Extensions.swift
//  swift-cam
//
//  Logging extensions and helpers
//

import OSLog
import Foundation

// MARK: - Logging

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.swift-cam"
    
    /// UI-related logging
    nonisolated static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// ML Model management logging
    nonisolated static let model = Logger(subsystem: subsystem, category: "Model")
    
    /// Performance and inference logging
    nonisolated static let performance = Logger(subsystem: subsystem, category: "Performance")
    
    /// Image processing logging
    nonisolated static let image = Logger(subsystem: subsystem, category: "Image")
    
    /// Camera setup logging
    nonisolated static let cameraSetup = Logger(subsystem: subsystem, category: "CameraSetup")
    
    /// BestShot logging
    nonisolated static let bestShot = Logger(subsystem: subsystem, category: "BestShot")

    /// Privacy-related logging (face detection, blurring)
    nonisolated static let privacy = Logger(subsystem: subsystem, category: "Privacy")
}

// MARK: - Conditional Logging Helpers

/// Helper functions for conditional logging based on build configuration
struct ConditionalLogger {
    /// Debug logging that only shows in DEBUG builds
    static func debug(_ logger: Logger, _ message: String) {
        #if DEBUG
        logger.debug("\(message)")
        #endif
    }
    
    /// Performance logging that only shows in DEBUG builds
    static func performance(_ logger: Logger, _ message: String) {
        #if DEBUG
        logger.info("\(message)")
        #endif
    }
}

