//
//  ModernResultsList.swift
//  swift-cam
//
//  Results list component
//

import SwiftUI

struct ModernResultsList: View {
    let results: [ClassificationResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recognition Results")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let topResult = results.first {
                    ModernConfidenceBadge(confidence: topResult.confidence)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(results.prefix(AppConstants.maxClassificationResults), id: \.identifier) { result in
                    ModernClassificationRow(result: result)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)).combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .move(edge: .trailing))
                        ))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
        )
        .animation(.spring(response: AppConstants.animationSpringResponse, dampingFraction: AppConstants.animationDampingFraction), value: results.count)
        .scaleEffect(results.isEmpty ? 1.0 : 1.0)
        .opacity(results.isEmpty ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.4), value: results.isEmpty)
        .id("results-\(results.first?.identifier ?? "empty")")
    }
}

