//
//  AppleStyleButton.swift
//  swift-cam
//
//  Apple-style button component
//

import SwiftUI

struct AppleStyleButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary, tertiary
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconForegroundColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(titleColor)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: style)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return Color.appAccent
        case .secondary: return Color.appLight
        case .tertiary: return Color.gray.opacity(0.1)
        }
    }
    
    private var titleColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .tertiary: return .primary
        }
    }
    
    private var iconBackgroundColor: Color {
        switch style {
        case .primary: return Color.white.opacity(0.2)
        case .secondary: return Color.appAccent.opacity(0.15)
        case .tertiary: return Color.gray.opacity(0.15)
        }
    }
    
    private var iconForegroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .appAccent
        case .tertiary: return .primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary: return Color.clear
        case .secondary: return Color.gray.opacity(0.2)
        case .tertiary: return Color.gray.opacity(0.15)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary: return 0
        case .secondary: return 1
        case .tertiary: return 1
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppleStyleButton(
            title: "Primary Action",
            subtitle: "The main CTA",
            icon: "star.fill",
            style: .primary
        )
        
        AppleStyleButton(
            title: "Secondary Action",
            subtitle: "An alternative option",
            icon: "arrow.right.circle",
            style: .secondary
        )
        
        AppleStyleButton(
            title: "Tertiary Action",
            subtitle: "A less common option",
            icon: "gearshape",
            style: .tertiary
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

