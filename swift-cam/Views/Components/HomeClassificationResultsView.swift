//
//  HomeClassificationResultsView.swift
//  swift-cam
//
//  Container for classification results display
//

import SwiftUI

struct HomeClassificationResultsView: View {
    let results: [ClassificationResult]
    let isAnalyzing: Bool
    let error: String?
    
    var body: some View {
        VStack(spacing: 16) {
            if let error = error {
                ErrorView(message: error)
                    .padding(.horizontal, 24)
            } else if !results.isEmpty {
                ResultsList(results: results)
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 1.05)).combined(with: .move(edge: .top))
                    ))
            } else if !isAnalyzing {
                EmptyResultsView()
                    .padding(.horizontal, 24)
            }
        }
    }
}

#Preview("With Results") {
    HomeClassificationResultsView(
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
    HomeClassificationResultsView(
        results: [],
        isAnalyzing: true,
        error: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Error") {
    HomeClassificationResultsView(
        results: [],
        isAnalyzing: false,
        error: "Failed to load model. Please check the model file."
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty") {
    HomeClassificationResultsView(
        results: [],
        isAnalyzing: false,
        error: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

