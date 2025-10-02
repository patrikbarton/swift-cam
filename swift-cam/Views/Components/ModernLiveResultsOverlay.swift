//
//  ModernLiveResultsOverlay.swift
//  swift-cam
//
//  Live camera results overlay
//

import SwiftUI

struct ModernLiveResultsOverlay: View {
    let results: [ClassificationResult]
    let isProcessing: Bool
    
    var body: some View {
        if !results.isEmpty {
            VStack(spacing: 8) {
                ForEach(results.prefix(4), id: \.identifier) { result in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(result.confidenceColor)
                            .frame(width: 8, height: 8)
                        
                        Text(result.displayName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(result.opacity)
                        
                        Spacer()
                        
                        Text("\(Int(result.confidence * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(result.confidenceColor.opacity(0.8))
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
}

