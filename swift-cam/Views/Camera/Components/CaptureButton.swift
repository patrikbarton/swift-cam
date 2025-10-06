//
//  CaptureButton.swift
//  swift-cam
//
//  Camera capture button component
//

import SwiftUI

struct CaptureButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Capture & Analyze")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CaptureButton(action: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

