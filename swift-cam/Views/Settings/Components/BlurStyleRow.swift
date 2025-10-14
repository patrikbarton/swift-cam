//
//  BlurStyleRow.swift
//  swift-cam
//
//  Blur style selection row component
//

import SwiftUI

/// Row component for selecting face blur style
struct BlurStyleRow: View {
    let style: BlurStyle
    let isSelected: Bool
    let onSelect: () -> Void
    private let hapticManager = HapticManagerService.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Optimized Icon Container
                Circle()
                    .fill(
                        isSelected ?
                        RadialGradient(
                            colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 15,
                            endRadius: 27
                        ) :
                        RadialGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 15,
                            endRadius: 27
                        )
                    )
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle()
                            .fill(
                                isSelected ?
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.6), Color.purple.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                    )
                    .overlay(
                        Circle()
                            .fill(.thinMaterial.opacity(isSelected ? 0.3 : 0.4))
                            .frame(width: 48, height: 48)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.purple.opacity(0.6) : Color.white.opacity(0.2),
                                lineWidth: 1.5
                            )
                            .frame(width: 48, height: 48)
                    )
                    .overlay(
                        Image(systemName: iconForStyle(style))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(style.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.purple)
                        .shadow(color: Color.purple.opacity(0.4), radius: 4, x: 0, y: 0)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: isSelected ?
                                        [Color.purple.opacity(0.15), Color.purple.opacity(0.05)] :
                                        [Color.white.opacity(0.05), Color.white.opacity(0.01)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                isSelected ? Color.purple.opacity(0.4) : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.purple.opacity(0.2) : Color.black.opacity(0.08),
                radius: isSelected ? 10 : 6,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func iconForStyle(_ style: BlurStyle) -> String {
        switch style {
        case .gaussian:
            return "eye.slash.fill"
        case .pixelated:
            return "square.grid.3x3.fill"
        case .blackBox:
            return "rectangle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        BlurStyleRow(style: .gaussian, isSelected: true, onSelect: {})
        BlurStyleRow(style: .pixelated, isSelected: false, onSelect: {})
        BlurStyleRow(style: .blackBox, isSelected: false, onSelect: {})
    }
    .padding()
    .background(Color.appPrimary.opacity(0.8))
}
