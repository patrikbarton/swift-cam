
//
//  HapticManager.swift
//  swift-cam
//
//  Created by Joshua Noeldeke on 10/13/25.
//

import UIKit

/// A singleton manager for providing haptic feedback.
class HapticManager {
    static let shared = HapticManager()

    private init() { }

    /// Triggers a notification-style haptic feedback.
    /// - Parameter type: The type of notification (`.success`, `.warning`, `.error`).
    func generate(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Triggers an impact-style haptic feedback.
    /// - Parameter style: The intensity of the impact (`.light`, `.medium`, `.heavy`, `.soft`, `.rigid`).
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
