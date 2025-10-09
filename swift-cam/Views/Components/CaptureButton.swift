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
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 4)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
            }
        }
    }
}

#Preview {
    CaptureButton(action: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

