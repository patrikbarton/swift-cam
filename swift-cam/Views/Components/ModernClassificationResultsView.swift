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

