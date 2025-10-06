//
//  ModernClassificationResultsView.swift
//  swift-cam
//
//  Container for classification results display
//

import SwiftUI

struct ModernClassificationResultsView: View {
    let results: [ClassificationResult]
    let isAnalyzing: Bool
    let error: String?
    
    var body: some View {
        VStack(spacing: 16) {
            if let error = error {
                ModernErrorView(message: error)
            } else if !results.isEmpty {
                ModernResultsList(results: results)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 1.05)).combined(with: .move(edge: .top))
                    ))
            } else if !isAnalyzing {
                ModernEmptyResultsView()
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview("With Results") {
    ModernClassificationResultsView(
        results: [
            ClassificationResult(identifier: "Labrador Retriever", confidence: 0.98),
            ClassificationResult(identifier: "Golden Retriever", confidence: 0.92),
            ClassificationResult(identifier: "Beagle", confidence: 0.87)
        ],
        isAnalyzing: false,
        error: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Analyzing") {
    ModernClassificationResultsView(
        results: [],
        isAnalyzing: true,
        error: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Error") {
    ModernClassificationResultsView(
        results: [],
        isAnalyzing: false,
        error: "Failed to load model. Please check the model file."
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty") {
    ModernClassificationResultsView(
        results: [],
        isAnalyzing: false,
        error: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

