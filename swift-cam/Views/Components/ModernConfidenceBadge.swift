//
//  ModernConfidenceBadge.swift
//  swift-cam
//
//  Confidence percentage badge
//

import SwiftUI

struct ModernConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            
            Text("\(Int(confidence * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(badgeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var badgeColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6...0.8: return .blue
        case 0.4...0.6: return .orange
        default: return .red
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        ModernConfidenceBadge(confidence: 0.95)
        ModernConfidenceBadge(confidence: 0.75)
        ModernConfidenceBadge(confidence: 0.55)
        ModernConfidenceBadge(confidence: 0.25)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

