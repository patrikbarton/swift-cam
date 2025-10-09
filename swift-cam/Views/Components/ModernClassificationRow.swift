//
//  ModernClassificationRow.swift
//  swift-cam
//
//  Individual classification result row
//

import SwiftUI

struct ModernClassificationRow: View {
    let result: ClassificationResult
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(result.confidenceColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: objectIcon(for: result.displayName))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(result.confidenceColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.displayName)
                    .font(.system(.body, design: .default, weight: .semibold)) // SF Pro
                    .foregroundColor(.black) // Dark text on white background
                
                Text("Confidence: \(Int(result.confidence * 100))%")
                    .font(.system(.subheadline, design: .default, weight: .medium)) // SF Pro
                    .foregroundColor(.gray) // Gray text for secondary info
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: CGFloat(result.confidence))
                    .stroke(result.confidenceColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: result.confidence)
            }
        }
        .padding(.vertical, 4)
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
    ModernClassificationRow(result: ClassificationResult(identifier: "Golden Retriever", confidence: 0.92))
        .padding()
        .background(Color(.systemGroupedBackground))
}

