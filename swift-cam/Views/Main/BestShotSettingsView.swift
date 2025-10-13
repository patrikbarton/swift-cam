
//
//  BestShotSettingsView.swift
//  swift-cam
//
//  Created by Joshua Noeldeke on 10/13/25.
//

import SwiftUI

struct BestShotSettingsView: View {
    @Binding var targetLabel: String
    let modelLabels: [String]
    
    @State private var labelInput: String = ""
    @FocusState private var isLabelFieldFocused: Bool

    private var filteredLabels: [String] {
        if labelInput.isEmpty {
            return modelLabels
        }
        return modelLabels.filter { $0.lowercased().contains(labelInput.lowercased()) }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: Color.appMixedGradient2, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack {
                    Text("Best Shot Target")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Choose a specific object for the camera to find")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 20)

                // Text Field with Autocomplete
                VStack(alignment: .leading, spacing: 16) {
                    Text("Target Label")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    HStack {
                        TextField("Enter object label...", text: $labelInput)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($isLabelFieldFocused)
                        
                        if modelLabels.contains(labelInput.lowercased()) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Suggestions List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredLabels, id: \.self) { label in
                            Button(action: {
                                self.labelInput = label
                                self.targetLabel = label
                                self.isLabelFieldFocused = false
                            }) {
                                HStack {
                                    Text(label.capitalized)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if label == targetLabel {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.appAccent)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Initialize the text field with the currently saved value
            labelInput = targetLabel
        }
        .navigationTitle("Best Shot Target")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @State var label = "cat"
    let labels = ["cat", "dog", "bird", "car", "bicycle", "boat"]
    
    return NavigationStack {
        BestShotSettingsView(targetLabel: $label, modelLabels: labels)
    }
}
