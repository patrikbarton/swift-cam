//
//  HomeClassificationResultsView.swift
//  swift-cam
//
//  Container for photo classification results display
//

import SwiftUI

/// Results container for Home tab classification
///
/// Orchestrates the display of classification results with proper
/// state handling:
/// - **Error**: Shows error message with icon
/// - **Results**: Shows formatted results list
/// - **Empty + Not Analyzing**: Shows empty state message
/// - **Analyzing**: Container is hidden (loading shown elsewhere)
///
/// **Animations:**
/// Uses asymmetric transitions for smooth appearance:
/// - Insertion: Fade + scale + slide from bottom
/// - Removal: Fade + scale + slide to top
///
/// **Usage:**
/// ```swift
/// HomeClassificationResultsView(
///     results: viewModel.classificationResults,
///     isAnalyzing: viewModel.isAnalyzing,
///     error: viewModel.errorMessage
/// )
/// ```
struct HomeClassificationResultsView: View {
    
    /// Classification results to display
    let results: [ClassificationResult]
    
    /// Whether analysis is in progress
    let isAnalyzing: Bool
    
    /// Optional error message
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

