//
//  ContentView.swift
//  swift-cam
//
//  Main view - UI only, business logic in CameraViewModel
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                LibraryView()
            }
            .tabItem {
                Image(systemName: "photo.on.rectangle")
                Text("Library")
            }
            
            LiveCameraView(cameraManager: LibraryViewModel(), selectedModel: .mobileNet)
                .tabItem {
                    Image(systemName: "camera")
                    Text("Live Camera")
                }
        }
    }
}





#Preview {
    ContentView()
}

