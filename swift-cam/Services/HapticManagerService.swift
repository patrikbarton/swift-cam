//
//  HapticManagerService.swift
//  swift-cam
//
//  Service for managing haptic feedback throughout the app
//

import UIKit

/// Service for providing haptic feedback
///
/// Centralizes all haptic feedback generation for consistent UX.
/// Creates new generator instances for each feedback event.
///
/// **Feedback Types:**
/// - Impact: Light, medium, heavy, soft, rigid physical touch feedback
/// - Notification: Success, warning, error semantic feedback
///
/// **Usage:**
/// ```swift
/// let haptics = HapticManagerService.shared
/// haptics.impact(.medium)  // Button press
/// haptics.generate(.success)  // Operation completed
/// ```
class HapticManagerService {
    static let shared = HapticManagerService()

    private init() { }

    // MARK: - Notification Feedback
    
    /// Generate notification haptic feedback
    ///
    /// Provides semantic feedback for user actions:
    /// - `.success`: Operation completed successfully
    /// - `.warning`: Warning or caution needed
    /// - `.error`: Operation failed
    ///
    /// - Parameter type: Type of notification (success, warning, error)
    func generate(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    // MARK: - Impact Feedback
    
    /// Generate impact haptic feedback
    ///
    /// Provides physical feedback for touch interactions:
    /// - `.light`: Subtle interaction (e.g., selection change)
    /// - `.medium`: Standard button tap
    /// - `.heavy`: Strong action (e.g., delete)
    /// - `.soft`: Gentle, cushioned impact
    /// - `.rigid`: Firm, solid impact
    ///
    /// - Parameter style: The intensity of the impact
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
