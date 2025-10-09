//
//  ModernImagePreviewView.swift
//  swift-cam
//
//  Image preview component with loading state
//

import SwiftUI

struct ModernImagePreviewView: View {
    let image: UIImage?
    let isAnalyzing: Bool
    var onClear: (() -> Void)? = nil // Optional closure for clearing image
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            
            if let image = image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: AppConstants.imageMaxHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(8)
                        .scaleEffect(isAnalyzing ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isAnalyzing)
                    
                    // X Button to clear image - top right corner
                    if let onClear = onClear, !isAnalyzing {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onClear()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16) // Padding from edge
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            } else {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    VStack(spacing: 6) {
                        Text("No Image Selected")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Capture or select a photo to identify objects")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
            }
            
            // Analysis Overlay
            if isAnalyzing {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.appAccent.opacity(0.2), lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .trim(from: 0, to: 0.7)
                                    .stroke(
                                        AngularGradient(
                                            colors: [Color.appAccent, Color.appPrimary],
                                            center: .center
                                        ),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnalyzing)
                            }
                            
                            Text("Analyzing Image...")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(minHeight: AppConstants.imageMinHeight, maxHeight: AppConstants.imageMaxHeightContainer)
        .padding(.horizontal, 24)
    }
}

#Preview("With Image") {
    ModernImagePreviewView(
        image: UIImage(systemName: "photo"),
        isAnalyzing: false,
        onClear: { print("Clear tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Analyzing") {
    ModernImagePreviewView(
        image: UIImage(systemName: "photo"),
        isAnalyzing: true,
        onClear: { print("Clear tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("No Image") {
    ModernImagePreviewView(
        image: nil,
        isAnalyzing: false,
        onClear: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

