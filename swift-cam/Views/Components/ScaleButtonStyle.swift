//
//  ScaleButtonStyle.swift
//  swift-cam
//
//  Reusable button style with scale animation
//

import SwiftUI

/// Button style that scales down when pressed
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    Button(action: {}) {
        Text("Press Me")
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding()
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(ScaleButtonStyle())
    .padding(50)
    .background(Color.gray)
}
