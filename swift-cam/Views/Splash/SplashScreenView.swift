//
//  SplashScreenView.swift
//  swift-cam
//
//  A view shown at app startup during initial model preloading.
//

import SwiftUI

/// A splash screen that provides visual feedback during the app's initial model preloading sequence.
///
/// This view is displayed by the root `SwiftCamApp` while the `AppStateViewModel` is
/// in its `isLoading` state. It features entrance animations and a real-time progress
/// bar that reflects the model loading progress.
///
/// **UI Layout:**
/// ```
/// ┌───────────────────────────┐
/// │                           │
/// │         [App Logo]        │
/// │                           │
/// │          AI Vision          │
/// │   Intelligent Recognition   │
/// │                           │
/// │             o             │
/// │      Loading Model...     │
/// │      [––––––––––––––]     │
/// │                           │
/// └───────────────────────────┘
/// ```
///
/// **State & Animation:**
/// - Observes `AppStateViewModel` from the environment to get `loadingProgress`, `currentModelNumber`, and `totalModels`.
/// - Uses local `@State` variables (`scale`, `opacity`) to drive a fade-and-scale entrance animation when the view appears.
/// - The root `SwiftCamApp` view automatically removes this view from the hierarchy when `appState.isLoading` becomes `false`.
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

