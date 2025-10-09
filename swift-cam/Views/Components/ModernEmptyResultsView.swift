//
//  ModernEmptyResultsView.swift
//  swift-cam
//
//  Empty state for classification results
//

import SwiftUI

struct ModernEmptyResultsView: View {
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
    ModernEmptyResultsView()
        .padding()
        .background(Color(.systemGroupedBackground))
}

