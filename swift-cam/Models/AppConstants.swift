//
//  AppConstants.swift
//  swift-cam
//
//  Application-wide constants
//

import CoreGraphics

enum AppConstants {
    static let preloadModels = true
    static let maxClassificationResults = 2 // Show only top 2 predictions
    static let modelSwitchDelayNanoseconds: UInt64 = 500_000_000 // 0.5 seconds
    static let animationSpringResponse: Double = 0.8
    static let animationDampingFraction: Double = 0.8
    static let imageMaxHeight: CGFloat = 280
    static let imageMinHeight: CGFloat = 200
    static let imageMaxHeightContainer: CGFloat = 300
}

