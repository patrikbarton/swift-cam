//
//  BestShotDurationSlider.swift
//  swift-cam
//
//  Custom slider component for Best Shot duration setting
//

import SwiftUI

struct BestShotDurationSlider: View {
    let icon: String
    let title: String
    let description: String
    @Binding var duration: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
                Spacer()
                Text("\(Int(duration))s")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            Slider(value: $duration, in: 3...30, step: 1)
                .tint(color)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    @State var duration: Double = 15.0
    return BestShotDurationSlider(
        icon: "timer",
        title: "Best Shot Duration",
        description: "Duration for the auto-capture sequence",
        duration: $duration,
        color: .cyan
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
