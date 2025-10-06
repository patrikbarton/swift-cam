//
//  AppConstants.swift
//  swift-cam
//
//  Application-wide constants
//

import CoreGraphics

enum AppConstants {
    // Whether to preload all ML models on app launch.
    // TODO: This should be a user-configurable setting.
    static let preloadModels = true
    
    // The maximum number of classification results to display in the library view.
    // TODO: This should be a user-configurable setting.
    static let libraryViewMaxResults = 5
    
    // The maximum number of classification results to display in the live camera view.
    // TODO: This should be a user-configurable setting.
    static let liveViewMaxResults = 5
    
    // The minimum confidence score for a classification to be displayed in the live view.
    // TODO: This should be made into a user-configurable setting in a future update.
    static let liveViewConfidenceThreshold: Float = 0.25
    
    // The minimum confidence score for a classification to be displayed in the library view.
    // TODO: This should also be a user-configurable setting.
    static let libraryViewConfidenceThreshold: Float = 0.0 // No filter by default
    
    static let modelSwitchDelayNanoseconds: UInt64 = 500_000_000 // 0.5 seconds
    static let animationSpringResponse: Double = 0.8
    static let animationDampingFraction: Double = 0.8
    static let imageMaxHeight: CGFloat = 280
    static let imageMinHeight: CGFloat = 200
    static let imageMaxHeightContainer: CGFloat = 300
}

