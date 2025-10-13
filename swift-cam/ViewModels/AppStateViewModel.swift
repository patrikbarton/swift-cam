//
//  AppStateViewModel.swift
//  swift-cam
//
//  ViewModel for app initialization and user settings coordination
//

import SwiftUI
import Combine
import OSLog

/// Manages app initialization and coordinates user settings
///
/// This ViewModel serves as the main coordinator for the application:
/// - Handles app startup and model preloading
/// - Provides access to user settings via `UserSettingsViewModel`
///
/// **Architecture:**
/// - Splits responsibilities between initialization and settings management
/// - `AppStateViewModel` handles splash screen and model loading
/// - `UserSettingsViewModel` handles persistent user preferences
///
/// **Usage:**
/// ```swift
/// @StateObject private var appState = AppStateViewModel()
/// 
/// // Access loading state
/// if appState.isLoading { SplashScreenView() }
/// 
/// // Access settings
/// appState.settings.selectedModel = .resnet50
/// ```
@MainActor
class AppStateViewModel: ObservableObject {
    
    // MARK: - Child ViewModels
    
    /// User settings (ML model, camera config, privacy, etc.)
    @Published var settings = UserSettingsViewModel()
    
    // MARK: - Loading State
    
    @Published var isLoading = true
    @Published var loadingProgress: String = "Initializing..."
    @Published var preloadDuration: TimeInterval = 0
    @Published var currentModelNumber: Int = 0
    @Published var totalModels: Int = 3
    
    // MARK: - Computed Properties (for backward compatibility)
    
    var selectedModel: MLModelType {
        get { settings.selectedModel }
        set { settings.selectedModel = newValue }
    }
    
    var fullScreenCamera: Bool {
        get { settings.fullScreenCamera }
        set { settings.fullScreenCamera = newValue }
    }
    
    var faceBlurringEnabled: Bool {
        get { settings.faceBlurringEnabled }
        set { settings.faceBlurringEnabled = newValue }
    }
    
    var livePreviewBlurEnabled: Bool {
        get { settings.livePreviewBlurEnabled }
        set { settings.livePreviewBlurEnabled = newValue }
    }
    
    var blurStyle: BlurStyle {
        get { settings.blurStyle }
        set { settings.blurStyle = newValue }
    }
    
    var isAssistedCaptureEnabled: Bool {
        get { settings.isAssistedCaptureEnabled }
        set { settings.isAssistedCaptureEnabled = newValue }
    }
    
    var includeLocationMetadata: Bool {
        get { settings.includeLocationMetadata }
        set { settings.includeLocationMetadata = newValue }
    }
    
    var bestShotTargetLabel: String {
        get { settings.bestShotTargetLabel }
        set { settings.bestShotTargetLabel = newValue }
    }
    
    var bestShotDuration: Double {
        get { settings.bestShotDuration }
        set { settings.bestShotDuration = newValue }
    }
    
    var highlightRules: [String: Double] {
        get { settings.highlightRules }
        set { settings.highlightRules = newValue }
    }
    
    // MARK: - Initialization
    
    init() {
        Task {
            if AppConstants.preloadModels {
                await startPreloading()
            } else {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Preloading
    
    /// Preload all ML models during app startup
    /// This ensures models are ready for instant use without first-time loading delays
    private func startPreloading() async {
        Logger.model.info("🚀 App starting - preloading pre-compiled ML models for optimal performance")
        
        let start = Date()
        
        await ModelPreloader.preloadAll { progressText in
            Task { @MainActor in
                self.loadingProgress = progressText
                
                // Parse progress (e.g., "Loading MobileNet V2... (1/3)")
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
        
        // Small delay for smooth transition
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        withAnimation(.easeOut(duration: 0.5)) {
            self.isLoading = false
        }
    }
}


