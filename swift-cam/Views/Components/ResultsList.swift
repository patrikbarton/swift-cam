//
//  ResultsList.swift
//  swift-cam
//
//  Results list component
//

import SwiftUI

struct ResultsList: View {
    let results: [ClassificationResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header with gradient text
            HStack(alignment: .center, spacing: 12) {
                Text("Recognition Results")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if let topResult = results.first {
                    ConfidenceBadge(confidence: topResult.confidence)
                }
            }
            
            // Results list
            VStack(spacing: 10) {
                ForEach(results.prefix(AppConstants.maxClassificationResults), id: \.identifier) { result in
                    ClassificationRow(result: result)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)).combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .move(edge: .trailing))
                        ))
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                // Premium glass morphism
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
        )
        .shadow(color: .black.opacity(0.15), radius: 25, y: 12)
        .animation(.spring(response: AppConstants.animationSpringResponse, dampingFraction: AppConstants.animationDampingFraction), value: results.count)
        .scaleEffect(results.isEmpty ? 1.0 : 1.0)
        .opacity(results.isEmpty ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.4), value: results.isEmpty)
        .id("results-\(results.first?.identifier ?? "empty")")
    }
}

#Preview {
    ResultsList(results: [
        ClassificationResult(identifier: "Labrador Retriever", confidence: 0.98),
        ClassificationResult(identifier: "Golden Retriever", confidence: 0.92),
        ClassificationResult(identifier: "Beagle", confidence: 0.87)
    ])
    .padding()
    .background(Color(.systemGroupedBackground))
}

