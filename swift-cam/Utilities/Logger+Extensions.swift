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
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    /// UI-related logging
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// ML Model management logging
    static let model = Logger(subsystem: subsystem, category: "Model")
    
    /// Performance and inference logging
    static let performance = Logger(subsystem: subsystem, category: "Performance")
    
    /// Image processing logging
    static let image = Logger(subsystem: subsystem, category: "Image")
    
    /// Camera setup logging
    static let cameraSetup = Logger(subsystem: subsystem, category: "CameraSetup")
}



