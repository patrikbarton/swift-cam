
//
//  BestShotResultsView.swift
//  swift-cam
//
//  Created by Joshua Noeldeke on 10/13/25.
//

import SwiftUI

struct BestShotResultsView: View {
    // The candidates passed from the camera view
    let candidates: [LiveCameraViewModel.CaptureCandidate]
    
    // The action to perform when the view is dismissed
    let onDismiss: () -> Void
    
    @State private var selectedImageData: [Data] = []
    private let photoSaver = PhotoSaverService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: Color.appPrimaryGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Best Shots")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Select the photos you want to keep.")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 20)
                        
                        // Image candidates grid
                        ForEach(candidates) { candidate in
                            ImageCandidateRow(candidate: candidate, isSelected: isSelected(candidate.imageData)) {
                                toggleSelection(candidate.imageData)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .tint(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Selected") {
                        for candidate in candidates where selectedImageData.contains(candidate.imageData) {
                            photoSaver.saveImageData(candidate.imageData, location: candidate.location)
                        }
                        onDismiss()
                    }
                    .bold()
                    .tint(.appAccent)
                    .disabled(selectedImageData.isEmpty)
                }
            }
        }
    }
    
    private func isSelected(_ data: Data) -> Bool {
        selectedImageData.contains(data)
    }
    
    private func toggleSelection(_ data: Data) {
        if let index = selectedImageData.firstIndex(of: data) {
            selectedImageData.remove(at: index)
        } else {
            selectedImageData.append(data)
        }
    }
}

// MARK: - Image Candidate Row
struct ImageCandidateRow: View {
    let candidate: LiveCameraViewModel.CaptureCandidate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                if let image = candidate.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            // Info overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Text(candidate.result.identifier.capitalized)
                                        .font(.callout).bold()
                                    Spacer()
                                    Text("\(Int(candidate.result.confidence * 100))%")
                                        .font(.callout)
                                }
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5))
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .frame(height: 300)
                        .overlay(Text("Preview not available").foregroundColor(.white))
                }
                
                // Selection checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.appAccent)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                        .padding(10)
                        .transition(.scale)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(), value: isSelected)
    }
}

//#if DEBUG
//// MARK: - Preview
//#Preview {
//    // Create some dummy data for the preview
//    let dummyResult = ClassificationResult(identifier: "Golden Retriever", confidence: 0.92)
//    let dummyImage = UIImage(systemName: "photo")!
//    let candidates = [
//        LiveCameraViewModel.CaptureCandidate(image: dummyImage, result: dummyResult),
//        LiveCameraViewModel.CaptureCandidate(image: UIImage(systemName: "photo.fill")!, result: ClassificationResult(identifier: "Labrador", confidence: 0.88))
//    ]
//    
//    return BestShotResultsView(candidates: candidates, onDismiss: {})
//}
//#endif
