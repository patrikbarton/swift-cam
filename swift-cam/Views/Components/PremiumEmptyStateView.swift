//
//  PremiumEmptyStateView.swift
//  swift-cam
//
//  Empty state view with animated icon and guidance text
//

import SwiftUI

/// Premium empty state with animated icons
struct PremiumEmptyStateView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated Icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.3 - Double(index) * 0.1),
                                    Color.appSecondary.opacity(0.2 - Double(index) * 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140 + CGFloat(index) * 30, height: 140 + CGFloat(index) * 30)
                        .opacity(isAnimating ? 0.0 : 0.5)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(
                            .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
                
                // Main icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent.opacity(0.4),
                                    Color.appSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 130, height: 130)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse.byLayer, options: .repeating, value: isAnimating)
                }
                .shadow(color: Color.appAccent.opacity(0.3), radius: 30, y: 15)
            }
            .padding(.vertical, 20)
            
            // Text Content
            VStack(spacing: 12) {
                Text("Ready to Analyze")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Select an image to see intelligent\nrecognition results")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 32)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.01)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.1), radius: 30, y: 15)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: Color.appPrimaryGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        PremiumEmptyStateView()
    }
}
