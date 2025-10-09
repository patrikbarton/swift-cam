//
//  AppStateViewModel.swift
//  swift-cam
//
//  ViewModel for app state and splash screen
//

import SwiftUI
import Combine
import OSLog

/// Manages app initialization state and model preloading
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

    init() {
        Task {
            if AppConstants.preloadModels {
                await startPreloading()
            } else {
                self.isLoading = false
            }
        }
    }

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

