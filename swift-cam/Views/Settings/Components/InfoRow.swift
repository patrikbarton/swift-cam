//
//  InfoRow.swift
//  swift-cam
//
//  Info display row component
//

import SwiftUI

/// Row component for displaying system information
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Optimized Icon Container
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 28
                    )
                )
                .frame(width: 52, height: 52)
                .overlay(
                    Circle()
                        .fill(.thinMaterial.opacity(0.5))
                        .frame(width: 48, height: 48)
                )
                .overlay(
                    Circle()
                        .strokeBorder(color.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 48, height: 48)
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                )
            
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.thinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.05), Color.white.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        InfoRow(
            icon: "cpu.fill",
            title: "Compute Unit",
            value: "Neural Engine",
            color: .orange
        )
        
        InfoRow(
            icon: "memorychip.fill",
            title: "Status",
            value: "Verified",
            color: .green
        )
    }
    .padding()
    .background(Color.appPrimary.opacity(0.8))
}
