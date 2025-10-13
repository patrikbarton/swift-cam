//
//  ConfidenceBadge.swift
//  swift-cam
//
//  Confidence percentage badge with color-coded indicator
//

import SwiftUI

/// Confidence percentage badge with pulsing indicator dot
///
/// Displays confidence as a percentage with color-coded visual feedback:
/// - **Green**: High confidence (50-100%)
/// - **Yellow**: Medium confidence (35-50%)
/// - **Orange**: Low confidence (20-35%)
/// - **Red**: Very low confidence (0-20%)
///
/// **Visual Elements:**
/// - Left: Pulsing colored dot with glow
/// - Right: Percentage text (e.g., "95%")
///
/// **Usage:**
/// ```swift
/// ConfidenceBadge(confidence: 0.95) // Shows "95%" with green dot
/// ```
struct ConfidenceBadge: View {
    
    /// Confidence value (0.0 to 1.0)
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 6) {
            // Pulsing indicator
            Circle()
                .fill(
                    RadialGradient(
                        colors: [badgeColor, badgeColor.opacity(0.8)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 6
                    )
                )
                .frame(width: 10, height: 10)
                .shadow(color: badgeColor.opacity(0.6), radius: 4, y: 0)
            
            Text("\(Int(confidence * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                badgeColor.opacity(0.3),
                                badgeColor.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Capsule()
                    .strokeBorder(badgeColor.opacity(0.5), lineWidth: 1.5)
            }
        )
        .shadow(color: badgeColor.opacity(0.3), radius: 8, y: 4)
    }
    
    private var badgeColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6...0.8: return .appAccent
        case 0.4...0.6: return .orange
        default: return .red
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        ConfidenceBadge(confidence: 0.95)
        ConfidenceBadge(confidence: 0.75)
        ConfidenceBadge(confidence: 0.55)
        ConfidenceBadge(confidence: 0.25)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

