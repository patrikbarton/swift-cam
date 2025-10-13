//
//  ClassificationRow.swift
//  swift-cam
//
//  Single classification result display row
//

import SwiftUI

/// Individual classification result row with confidence indicator
///
/// Displays a single ML classification result with:
/// - Confidence-colored icon badge
/// - Object name (formatted, capitalized)
/// - Confidence percentage
/// - Glass morphism design
///
/// **Visual Design:**
/// - Left: Circular icon with gradient based on confidence
/// - Center: Object name in white text
/// - Right: Confidence badge with percentage
///
/// **Color Coding:**
/// - Green: 50-100% confidence
/// - Yellow: 35-50% confidence
/// - Orange: 20-35% confidence
/// - Red: Below 20% confidence
///
/// **Usage:**
/// ```swift
/// ClassificationRow(result: ClassificationResult(
///     identifier: "keyboard",
///     confidence: 0.95
/// ))
/// ```
struct ClassificationRow: View {
    
    /// The classification result to display
    let result: ClassificationResult
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon container with glass effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                result.confidenceColor.opacity(0.3),
                                result.confidenceColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Circle()
                    .strokeBorder(result.confidenceColor.opacity(0.4), lineWidth: 1)
                    .frame(width: 48, height: 48)
                
                Image(systemName: objectIcon(for: result.displayName))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [result.confidenceColor, result.confidenceColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(result.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text("Confidence: \(Int(result.confidence * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Premium circular progress indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 3.5)
                    .frame(width: 42, height: 42)
                
                Circle()
                    .trim(from: 0, to: CGFloat(result.confidence))
                    .stroke(
                        LinearGradient(
                            colors: [result.confidenceColor, result.confidenceColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: result.confidence)
                    .shadow(color: result.confidenceColor.opacity(0.4), radius: 4, y: 2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            }
        )
    }
    
    private func objectIcon(for name: String) -> String {
        let lowercased = name.lowercased()
        switch lowercased {
        case let x where x.contains("dog"): return "dog.fill"
        case let x where x.contains("cat"): return "cat.fill"
        case let x where x.contains("car"): return "car.fill"
        case let x where x.contains("person"): return "person.fill"
        case let x where x.contains("food"): return "fork.knife"
        case let x where x.contains("plant"): return "leaf.fill"
        case let x where x.contains("building"): return "building.2.fill"
        default: return "viewfinder.circle.fill"
        }
    }
}

#Preview {
    ClassificationRow(result: ClassificationResult(identifier: "Golden Retriever", confidence: 0.92))
        .padding()
        .background(Color(.systemGroupedBackground))
}


