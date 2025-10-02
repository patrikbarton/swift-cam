//
//  SplashScreenView.swift
//  swift-cam
//
//  Startup splash screen that preloads all pre-compiled ML models into memory
//  Splash duration is dynamically based on actual model loading time (not fixed)
//

import SwiftUI
import Combine
import OSLog
import CoreML

// MARK: - App State Manager
@MainActor
class AppState: ObservableObject {
    @Published var isLoading = true
    @Published var loadingProgress: String = "Initializing..."
    @Published var preloadDuration: TimeInterval = 0
    @Published var currentModelNumber: Int = 0
    @Published var totalModels: Int = 3

    init() {
        Task {
            await startPreloading()
        }
    }

    private func startPreloading() async {
        Logger.model.info("🚀 App starting - preloading pre-compiled ML models for optimal performance")

        let start = Date()

        // Preload all ML models: Xcode has already compiled models to .mlmodelc format during build.
        // This loads them into memory and ensures they're cached by CoreML for instant use.
        await ModelPreloader.preloadAll { progressText in
            // Update UI on main actor
            Task { @MainActor in
                self.loadingProgress = progressText
                
                // Parse model number from progress text if it contains (x/y) format
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

        // Short delay to show "Ready!" message before transition
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Transition off the splash only after the real preload completes
        withAnimation(.easeOut(duration: 0.5)) {
            self.isLoading = false
        }
    }
}

// MARK: - Splash Screen View
struct SplashScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var showTagline = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.9),
                    Color(red: 0.2, green: 0.6, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon/Logo
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 34))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                VStack(spacing: 12) {
                    Text("AI Vision")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showTagline ? 1 : 0)
                    
                    Text("Intelligent Object Recognition")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(showTagline ? 1 : 0)
                }
                
                Spacer()
                
                // Loading indicator with progress text
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    // Progress text with model loading status
                    Text(appState.loadingProgress)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut(duration: 0.3), value: appState.loadingProgress)
                    
                    // Progress indicator bar
                    if appState.totalModels > 0 && appState.currentModelNumber > 0 {
                        VStack(spacing: 6) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    // Progress bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: geometry.size.width * (CGFloat(appState.currentModelNumber) / CGFloat(appState.totalModels)), height: 4)
                                        .animation(.easeInOut(duration: 0.3), value: appState.currentModelNumber)
                                }
                            }
                            .frame(height: 4)
                            
                            Text("\(appState.currentModelNumber) of \(appState.totalModels) models")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(width: 200)
                    }
                }
                .opacity(showTagline ? 1 : 0)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Animate logo entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Show tagline after logo
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showTagline = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView()
        .environmentObject(AppState())
}
