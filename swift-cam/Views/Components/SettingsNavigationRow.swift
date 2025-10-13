//
//  SettingsNavigationRow.swift
//  swift-cam
//
//  Generic navigation row for settings
//

import SwiftUI

struct SettingsNavigationRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    NavigationStack {
        List {
            SettingsNavigationRow(
                icon: "scope",
                iconColor: .orange,
                title: "Best Shot Target",
                subtitle: "None",
                destination: Text("Best Shot Settings")
            )
            
            SettingsNavigationRow(
                icon: "sparkles",
                iconColor: .appAccent,
                title: "Highlight Rules",
                subtitle: "Configure objects to highlight in the camera",
                destination: Text("Highlight Settings")
            )
        }
        .listStyle(.plain)
        .background(
            LinearGradient(
                colors: Color.appMixedGradient2,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}
