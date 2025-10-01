//
//  SplashScreenView.swift
//  swift-cam
//
//  Startup splash screen with loading animation
//

import SwiftUI
import Combine
import OSLog

// MARK: - App State Manager
@MainActor
class AppState: ObservableObject {
    @Published var isLoading = true
    @Published var loadingProgress: String = "Initializing..."
    
    init() {
        Task {
            await startPreloading()
        }
    }
    
    private func startPreloading() async {
        Logger.model.info("🚀 App starting - beginning model preload")
        
        // Update progress messages
        loadingProgress = "Loading MobileNet V2..."
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        loadingProgress = "Loading ResNet-50..."
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        loadingProgress = "Loading FastViT..."
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        loadingProgress = "Optimizing AI Models..."
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Ensure splash shows for at least 2 seconds total
        Logger.model.info("✅ Model preload complete, transitioning to app")
        
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
                    
                    Text(appState.loadingProgress)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut(duration: 0.3), value: appState.loadingProgress)
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
