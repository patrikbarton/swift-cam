//
//  ImagePreviewView.swift
//  swift-cam
//
//  Image preview component with loading state and clear action
//

import SwiftUI

/// Image preview with glass morphism design and loading overlay
///
/// Displays a selected or captured image with:
/// - Glass card background
/// - Loading spinner overlay (when analyzing)
/// - Clear button (X) in top-right corner
/// - Rounded corners and shadow
///
/// **States:**
/// - **Image + Not Analyzing**: Show image with clear button
/// - **Image + Analyzing**: Show image with loading overlay
/// - **No Image**: Show placeholder message
///
/// **Usage:**
/// ```swift
/// ImagePreviewView(
///     image: capturedImage,
///     isAnalyzing: viewModel.isAnalyzing,
///     onClear: { viewModel.clearImage() }
/// )
/// ```
struct ImagePreviewView: View {
    
    /// Image to display (nil for placeholder)
    let image: UIImage?
    
    /// Whether analysis is in progress
    let isAnalyzing: Bool
    
    /// Optional action when clear button tapped
    var onClear: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Premium glass background
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.15), radius: 25, y: 12)
            
            if let image = image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: AppConstants.imageMaxHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(12)
                        .scaleEffect(isAnalyzing ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isAnalyzing)
                    
                    // Premium X Button to clear image
                    if let onClear = onClear, !isAnalyzing {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                onClear()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.4),
                                                Color.black.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Circle()
                                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(20)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            } else {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    VStack(spacing: 6) {
                        Text("No Image Selected")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Capture or select a photo to identify objects")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
            }
            
            // Premium Analysis Overlay
            if isAnalyzing {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        ZStack {
                            // Subtle gradient overlay
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appAccent.opacity(0.1),
                                            Color.appSecondary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(spacing: 20) {
                                // Animated spinner
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                        .frame(width: 56, height: 56)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.7)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.appAccent, Color.appSecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                        )
                                        .frame(width: 56, height: 56)
                                        .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnalyzing)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("Analyzing Image")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    Text("Using AI to identify objects...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(minHeight: AppConstants.imageMinHeight, maxHeight: AppConstants.imageMaxHeightContainer)
        .padding(.horizontal, 24)
    }
}

#Preview("With Image") {
    ImagePreviewView(
        image: UIImage(systemName: "photo"),
        isAnalyzing: false,
        onClear: { print("Clear tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Analyzing") {
    ImagePreviewView(
        image: UIImage(systemName: "photo"),
        isAnalyzing: true,
        onClear: { print("Clear tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("No Image") {
    ImagePreviewView(
        image: nil,
        isAnalyzing: false,
        onClear: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

