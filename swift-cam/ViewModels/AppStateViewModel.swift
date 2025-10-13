//
//  AppStateViewModel.swift
//  swift-cam
//
//  ViewModel for app state and splash screen
//

import SwiftUI
import Combine
import OSLog

/// Manages app initialization state, user preferences, and ML model preloading
///
/// This ViewModel serves as the central state manager for the application, handling:
/// - App startup and model preloading during splash screen
/// - User preferences (selected ML model, camera settings, privacy options)
/// - Persistent storage of settings using UserDefaults
///
/// **Key Responsibilities:**
/// - Preload all ML models during app startup for instant access
/// - Persist and restore user settings across app launches
/// - Manage highlight rules for live camera detection
/// - Configure Best Shot capture parameters
///
/// **Usage:**
/// ```swift
/// @StateObject private var appState = AppStateViewModel()
/// ```
@MainActor
class AppStateViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var loadingProgress: String = "Initializing..."
    @Published var preloadDuration: TimeInterval = 0
    @Published var currentModelNumber: Int = 0
    @Published var totalModels: Int = 3
    @Published var fullScreenCamera: Bool = false // Camera size preference
    @Published var faceBlurringEnabled: Bool = false // Face privacy protection
    @Published var blurStyle: BlurStyle = .gaussian // Face blur style

    @Published var selectedModel: MLModelType = .mobileNet {
        didSet {
            saveSelectedModel()
        }
    }

    @Published var bestShotTargetLabel: String = "" {
        didSet {
            saveBestShotTargetLabel()
        }
    }

    @Published var isAssistedCaptureEnabled: Bool = false {
        didSet {
            saveIsAssistedCaptureEnabled()
        }
    }

    @Published var bestShotDuration: Double = 10.0 {
        didSet {
            saveBestShotDuration()
        }
    }

    @Published var highlightRules: [String: Double] = ["keyboard": 0.8] {
        didSet {
            saveHighlightRules()
        }
    }

    private let highlightRulesKey = "highlightRules"
    private let bestShotDurationKey = "bestShotDuration"
    private let selectedModelKey = "selectedModel"
    private let bestShotTargetLabelKey = "bestShotTargetLabel"
    private let isAssistedCaptureEnabledKey = "isAssistedCaptureEnabled"

    init() {
        loadHighlightRules()
        loadBestShotDuration()
        loadSelectedModel()
        loadBestShotTargetLabel()
        loadIsAssistedCaptureEnabled()
        
        Task {
            if AppConstants.preloadModels {
                await startPreloading()
            } else {
                self.isLoading = false
            }
        }
    }

    /// Load all settings from UserDefaults
    private func loadIsAssistedCaptureEnabled() {
        self.isAssistedCaptureEnabled = UserDefaults.standard.bool(forKey: isAssistedCaptureEnabledKey)
    }

    /// Save Assisted Capture setting to UserDefaults
    private func saveIsAssistedCaptureEnabled() {
        UserDefaults.standard.set(isAssistedCaptureEnabled, forKey: isAssistedCaptureEnabledKey)
    }

    private func loadBestShotTargetLabel() {
        self.bestShotTargetLabel = UserDefaults.standard.string(forKey: bestShotTargetLabelKey) ?? ""
    }

    private func saveBestShotTargetLabel() {
        UserDefaults.standard.set(bestShotTargetLabel, forKey: bestShotTargetLabelKey)
    }

    private func loadSelectedModel() {
        if let modelRawValue = UserDefaults.standard.string(forKey: selectedModelKey) {
            if let model = MLModelType(rawValue: modelRawValue) {
                self.selectedModel = model
            }
        }
    }

    private func saveSelectedModel() {
        UserDefaults.standard.set(selectedModel.rawValue, forKey: selectedModelKey)
    }

    private func loadBestShotDuration() {
        if UserDefaults.standard.object(forKey: bestShotDurationKey) != nil {
            self.bestShotDuration = UserDefaults.standard.double(forKey: bestShotDurationKey)
        }
    }

    private func saveBestShotDuration() {
        UserDefaults.standard.set(bestShotDuration, forKey: bestShotDurationKey)
    }

    private func loadHighlightRules() {
        if let data = UserDefaults.standard.data(forKey: highlightRulesKey) {
            if let decodedRules = try? JSONDecoder().decode([String: Double].self, from: data) {
                self.highlightRules = decodedRules
                return
            }
        }
        // Load default if nothing in UserDefaults
        self.highlightRules = ["keyboard": 0.8, "mouse": 0.8, "laptop": 0.8]
    }

    private func saveHighlightRules() {
        if let encoded = try? JSONEncoder().encode(highlightRules) {
            UserDefaults.standard.set(encoded, forKey: highlightRulesKey)
        }
    }

    /// Preload all ML models during app startup
    /// This ensures models are ready for instant use without first-time loading delays
    private func startPreloading() async {
        Logger.model.info("🚀 App starting - preloading pre-compiled ML models for optimal performance")

        let start = Date()

        await ModelPreloader.preloadAll { progressText in
            Task { @MainActor in
                self.loadingProgress = progressText
                
                if let match = progressText.range(of: "\\((\\d+)/(\\d+)\\)", options: .regularExpression) {
                    let numbers = progressText[match].dropFirst().dropLast().split(separator: "/")
                    if numbers.count == 2, 
                       let current = Int(numbers[0]), 
                       let total = Int(numbers[1]) {
                        self.currentModelNumber = current
                        self.totalModels = total
                    }
                }
            }
        }

        let elapsed = Date().timeIntervalSince(start)
        self.preloadDuration = elapsed
        Logger.model.info("✅ Model preload complete - took \(String(format: "%.2f", elapsed))s to load and cache all models")

        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        withAnimation(.easeOut(duration: 0.5)) {
            self.isLoading = false
        }
    }
}

