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
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                Text("Ready to Analyze")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Select an image to see intelligent recognition results")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
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

