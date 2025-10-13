//
//  EmptyResultsView.swift
//  swift-cam
//
//  Empty state placeholder for no classification results
//

import SwiftUI

/// Empty state view when no classification results exist
///
/// Friendly placeholder shown when:
/// - No image has been selected yet
/// - Classification hasn't been performed
/// - User has cleared previous results
///
/// **Design:**
/// - Sparkles icon in accent color
/// - "Ready to Analyze" heading
/// - Helpful guidance text
/// - Centered, clean layout
///
/// **Usage:**
/// ```swift
/// if results.isEmpty && !isAnalyzing {
///     EmptyResultsView()
/// }
/// ```
struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.appAccent)
            }
            
            VStack(spacing: 4) {
                Text("Ready to Analyze")
                    .font(.system(.title3, design: .rounded, weight: .semibold)) // SF Pro
                    .foregroundColor(.black) // Dark text on white background
                
                Text("Select an image to see intelligent recognition results")
                    .font(.system(.subheadline, design: .default, weight: .medium)) // SF Pro
                    .foregroundColor(.gray) // Gray for secondary text
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    EmptyResultsView()
        .padding()
        .background(Color(.systemGroupedBackground))
}

