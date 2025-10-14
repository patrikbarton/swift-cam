//
//  UserSettingsViewModel.swift
//  swift-cam
//
//  ViewModel for managing user preferences and settings
//

import SwiftUI
import Combine
import OSLog

/// Manages user preferences and settings
///
/// This ViewModel handles all persistent user settings including:
/// - ML model selection
/// - Camera configuration (full screen, assisted capture)
/// - Privacy settings (face blurring)
/// - Best Shot parameters
/// - Highlight rules
///
/// All settings are automatically persisted to UserDefaults and restored on app launch.
///
/// **Usage:**
/// ```swift
/// @StateObject private var settings = UserSettingsViewModel()
/// 
/// settings.selectedModel = .resnet50
/// settings.faceBlurringEnabled = true
/// ```
@MainActor
class UserSettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedModel: MLModelType = .mobileNet {
        didSet { saveSelectedModel() }
    }
    
    @Published var fullScreenCamera: Bool = false {
        didSet { UserDefaults.standard.set(fullScreenCamera, forKey: Keys.fullScreenCamera) }
    }
    
    @Published var faceBlurringEnabled: Bool = false {
        didSet { UserDefaults.standard.set(faceBlurringEnabled, forKey: Keys.faceBlurring) }
    }
    
    @Published var livePreviewBlurEnabled: Bool = false {
        didSet { UserDefaults.standard.set(livePreviewBlurEnabled, forKey: Keys.livePreviewBlur) }
    }
    
    @Published var blurStyle: BlurStyle = .gaussian {
        didSet { saveBlurStyle() }
    }
    
    @Published var isAssistedCaptureEnabled: Bool = false {
        didSet { UserDefaults.standard.set(isAssistedCaptureEnabled, forKey: Keys.assistedCapture) }
    }
    
    @Published var includeLocationMetadata: Bool = false {
        didSet { UserDefaults.standard.set(includeLocationMetadata, forKey: Keys.locationMetadata) }
    }
    
    @Published var bestShotTargetLabel: String = "" {
        didSet { UserDefaults.standard.set(bestShotTargetLabel, forKey: Keys.bestShotTarget) }
    }
    
    @Published var bestShotDuration: Double = 10.0 {
        didSet { UserDefaults.standard.set(bestShotDuration, forKey: Keys.bestShotDuration) }
    }
    
    @Published var bestShotConfidenceThreshold: Double = 0.80 {
        didSet { UserDefaults.standard.set(bestShotConfidenceThreshold, forKey: Keys.bestShotConfidenceThreshold) }
    }
    
    @Published var highlightRules: [String: Double] = [:] {
        didSet { saveHighlightRules() }
    }
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let selectedModel = "selectedModel"
        static let fullScreenCamera = "fullScreenCamera"
        static let faceBlurring = "faceBlurringEnabled"
        static let livePreviewBlur = "livePreviewBlurEnabled"
        static let blurStyle = "blurStyle"
        static let assistedCapture = "isAssistedCaptureEnabled"
        static let locationMetadata = "includeLocationMetadata"
        static let bestShotTarget = "bestShotTargetLabel"
        static let bestShotDuration = "bestShotDuration"
        static let bestShotConfidenceThreshold = "bestShotConfidenceThreshold"
        static let highlightRules = "highlightRules"
    }
    
    // MARK: - Initialization
    
    init() {
        loadAllSettings()
    }
    
    // MARK: - Loading
    
    /// Load all settings from UserDefaults
    private func loadAllSettings() {
        loadSelectedModel()
        loadFullScreenCamera()
        loadFaceBlurring()
        loadLivePreviewBlur()
        loadBlurStyle()
        loadAssistedCapture()
        loadLocationMetadata()
        loadBestShotTarget()
        loadBestShotDuration()
        loadBestShotConfidenceThreshold()
        loadHighlightRules()
    }
    
    private func loadSelectedModel() {
        if let modelRawValue = UserDefaults.standard.string(forKey: Keys.selectedModel),
           let model = MLModelType(rawValue: modelRawValue) {
            selectedModel = model
        }
    }
    
    private func loadFullScreenCamera() {
        if UserDefaults.standard.object(forKey: Keys.fullScreenCamera) != nil {
            fullScreenCamera = UserDefaults.standard.bool(forKey: Keys.fullScreenCamera)
        }
    }
    
    private func loadFaceBlurring() {
        if UserDefaults.standard.object(forKey: Keys.faceBlurring) != nil {
            faceBlurringEnabled = UserDefaults.standard.bool(forKey: Keys.faceBlurring)
        }
    }
    
    private func loadLivePreviewBlur() {
        if UserDefaults.standard.object(forKey: Keys.livePreviewBlur) != nil {
            livePreviewBlurEnabled = UserDefaults.standard.bool(forKey: Keys.livePreviewBlur)
        }
    }
    
    private func loadBlurStyle() {
        if let styleRawValue = UserDefaults.standard.string(forKey: Keys.blurStyle),
           let style = BlurStyle(rawValue: styleRawValue) {
            blurStyle = style
        }
    }
    
    private func loadAssistedCapture() {
        if UserDefaults.standard.object(forKey: Keys.assistedCapture) != nil {
            isAssistedCaptureEnabled = UserDefaults.standard.bool(forKey: Keys.assistedCapture)
        }
    }
    
    private func loadLocationMetadata() {
        if UserDefaults.standard.object(forKey: Keys.locationMetadata) != nil {
            includeLocationMetadata = UserDefaults.standard.bool(forKey: Keys.locationMetadata)
        }
    }
    
    private func loadBestShotTarget() {
        if let target = UserDefaults.standard.string(forKey: Keys.bestShotTarget) {
            bestShotTargetLabel = target
        }
    }
    
    private func loadBestShotDuration() {
        if UserDefaults.standard.object(forKey: Keys.bestShotDuration) != nil {
            bestShotDuration = UserDefaults.standard.double(forKey: Keys.bestShotDuration)
        } else {
            bestShotDuration = 10.0 // Default
        }
    }
    
    private func loadBestShotConfidenceThreshold() {
        if UserDefaults.standard.object(forKey: Keys.bestShotConfidenceThreshold) != nil {
            bestShotConfidenceThreshold = UserDefaults.standard.double(forKey: Keys.bestShotConfidenceThreshold)
        } else {
            bestShotConfidenceThreshold = 0.80 // Default
        }
    }
    
    private func loadHighlightRules() {
        if let data = UserDefaults.standard.data(forKey: Keys.highlightRules),
           let decodedRules = try? JSONDecoder().decode([String: Double].self, from: data) {
            highlightRules = decodedRules
        } else {
            // Default rules
            highlightRules = ["keyboard": 0.8, "mouse": 0.8, "laptop": 0.8]
        }
    }
    
    // MARK: - Saving
    
    private func saveSelectedModel() {
        UserDefaults.standard.set(selectedModel.rawValue, forKey: Keys.selectedModel)
    }
    
    private func saveBlurStyle() {
        UserDefaults.standard.set(blurStyle.rawValue, forKey: Keys.blurStyle)
    }
    
    private func saveHighlightRules() {
        if let encoded = try? JSONEncoder().encode(highlightRules) {
            UserDefaults.standard.set(encoded, forKey: Keys.highlightRules)
        }
    }
    
    // MARK: - Reset
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        selectedModel = .mobileNet
        fullScreenCamera = false
        faceBlurringEnabled = false
        blurStyle = .gaussian
        isAssistedCaptureEnabled = false
        includeLocationMetadata = false
        bestShotTargetLabel = ""
        bestShotDuration = 10.0
        bestShotConfidenceThreshold = 0.80
        highlightRules = ["keyboard": 0.8, "mouse": 0.8, "laptop": 0.8]
        
        Logger.ui.info("User settings reset to defaults")
    }
}
