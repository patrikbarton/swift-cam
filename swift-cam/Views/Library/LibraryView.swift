import SwiftUI
import PhotosUI
import OSLog

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedImage: PhotosPickerItem? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            ModernImagePreviewView(
                image: viewModel.capturedImage,
                isAnalyzing: viewModel.isAnalyzing
            )
            
            ModernClassificationResultsView(
                results: viewModel.classificationResults,
                isAnalyzing: viewModel.isAnalyzing,
                error: viewModel.errorMessage
            )
            
            PhotosPicker(
                selection: $selectedImage,
                matching: .images,
                photoLibrary: .shared()
            ) {
                AppleStyleButton(
                    title: "Photo Library",
                    subtitle: "Choose from your photos",
                    icon: "photo.on.rectangle.angled",
                    style: .secondary
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isLoadingModel || viewModel.isAnalyzing || viewModel.isSwitchingModel)
            
            if viewModel.capturedImage != nil {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.clearImage()
                    }
                }) {
                    AppleStyleButton(
                        title: "Clear Image",
                        subtitle: "Start over",
                        icon: "arrow.counterclockwise",
                        style: .tertiary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .onChange(of: selectedImage) { _, newItem in
            Task {
                await handleImageSelection(newItem)
            }
        }
    }
    
    private func handleImageSelection(_ newItem: PhotosPickerItem?) async {
        guard let newItem = newItem else { return }
        
        viewModel.errorMessage = nil
        
        do {
            if let data = try? await newItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    await viewModel.classifyImage(image)
                    return
                } else {
                    throw ImageLoadingError.corruptedData
                }
            } else {
                throw ImageLoadingError.unsupportedFormat
            }
            
        } catch let error as ImageLoadingError {
            Logger.image.error("Image loading failed: \(error.localizedDescription)")
            viewModel.errorMessage = error.localizedDescription
        } catch {
            Logger.image.error("Image loading failed with unknown error: \(error.localizedDescription)")
            viewModel.errorMessage = ImageLoadingError.accessDenied.localizedDescription
        }
        
        selectedImage = nil
    }
}

#if DEBUG
#Preview {
    LibraryView()
}
#endif
