//
//  SplashScreenView.swift
//  swift-cam
//
//  Startup splash screen with ML model preloading
//

import SwiftUI

/// Splash screen displayed during app initialization
///
/// Shown on first launch and during model preloading. Provides visual
/// feedback on loading progress while ML models are compiled and cached.
///
/// **Responsibilities:**
/// - Display app branding (logo, name, tagline)
/// - Show loading progress with model count
/// - Animate entrance (scale, opacity, fade-in)
/// - Transition smoothly to main content
///
/// **Loading Sequence:**
/// 1. Logo scales in with fade
/// 2. App name and tagline appear
/// 3. Progress indicator shows model loading
/// 4. Individual model names displayed as they load
/// 5. Auto-transitions when complete (~2 seconds total)
///
/// **UI Animation:**
/// - Logo: Scale 0.8→1.0 + opacity 0→1
/// - Text: Staggered fade-in
/// - Progress: Real-time updates from AppStateViewModel
///
/// **Integration:**
/// Reads state from `AppStateViewModel` via `@EnvironmentObject`.
/// View automatically dismisses when `isLoading` becomes false.
struct SplashScreenView: View {
    
    // MARK: - Environment
    
    /// App state providing loading progress
    @EnvironmentObject var appState: AppStateViewModel
    
    // MARK: - Animation State
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var showTagline = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: Color.appMixedGradient1,
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
                    
                    Text(appState.loadingProgress)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut(duration: 0.3), value: appState.loadingProgress)
                    
                    // Progress indicator bar
                    if appState.totalModels > 0 && appState.currentModelNumber > 0 {
                        VStack(spacing: 6) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                    
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
            scale = 1.0
            opacity = 1.0
            showTagline = true
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AppStateViewModel())
}

