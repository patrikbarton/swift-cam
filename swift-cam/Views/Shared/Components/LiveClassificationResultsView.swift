//
//  LiveClassificationResultsView.swift
//  swift-cam
//
//  Live classification results display (new design)
//

import SwiftUI

struct LiveClassificationResultsView: View {
    let results: [ClassificationResult]
    let model: MLModelType

    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Text("Live Detection")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Text(model.shortName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)

            // Results
            if results.isEmpty {
                Text("Point the camera at an object...")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(results.prefix(3).enumerated()), id: \.element.identifier) { (index, result) in
                        LiveClassificationRow(rank: index + 1, result: result)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(20)
    }
}

#Preview("With Results") {
    LiveClassificationResultsView(
        results: [
            ClassificationResult(identifier: "Golden Retriever", confidence: 0.92),
            ClassificationResult(identifier: "Labrador Retriever", confidence: 0.88),
        ],
        model: .mobileNet
    )
    .padding()
    .background(Color.gray)
}

#Preview("Empty") {
    LiveClassificationResultsView(results: [], model: .mobileNet)
        .padding()
        .background(Color.gray)
}

struct LiveClassificationRow: View {
    let rank: Int
    let result: ClassificationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                Text(result.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(result.confidence * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(result.confidenceColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 6)
                    Capsule()
                        .fill(result.confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(result.confidence), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

