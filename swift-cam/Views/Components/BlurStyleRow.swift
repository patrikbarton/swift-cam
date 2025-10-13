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
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconForStyle(style))
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(style.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.purple)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
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
