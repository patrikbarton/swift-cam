//
//  CameraSettingToggleRow.swift
//  swift-cam
//
//  Toggle row component for camera settings
//

import SwiftUI

/// Toggle row for camera setting options
struct CameraSettingToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Optimized Icon Container
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 15,
                        endRadius: 31
                    )
                )
                .frame(width: 62, height: 62)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                )
                .overlay(
                    Circle()
                        .fill(.thinMaterial.opacity(0.4))
                        .frame(width: 56, height: 56)
                )
                .overlay(
                    Circle()
                        .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(color)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer()

            // Optimized Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
                .scaleEffect(1.1)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: isOn ?
                                    [color.opacity(0.15), color.opacity(0.05)] :
                                    [Color.white.opacity(0.05), Color.white.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isOn ? color.opacity(0.4) : Color.white.opacity(0.15),
                            lineWidth: isOn ? 1.5 : 1
                        )
                )
        )
        .shadow(
            color: isOn ? color.opacity(0.15) : Color.black.opacity(0.08),
            radius: isOn ? 10 : 6,
            y: isOn ? 4 : 2
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var isToggle1On = true
        @State var isToggle2On = false
        
        var body: some View {
            VStack(spacing: 12) {
                CameraSettingToggleRow(
                    icon: "face.smiling",
                    title: "Blur Faces in Photos",
                    description: "Blur faces in captured photos",
                    isOn: $isToggle1On,
                    color: .purple
                )
                
                CameraSettingToggleRow(
                    icon: "location.fill",
                    title: "Include Location",
                    description: "Embed GPS coordinates in saved photos",
                    isOn: $isToggle2On,
                    color: .green
                )
            }
            .padding()
            .background(Color.appPrimary.opacity(0.8))
        }
    }
    
    return PreviewWrapper()
}
