

import SwiftUI

@main
struct swift_camApp: App {
    @StateObject private var appState = AppStateViewModel()
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoading {
                SplashScreenView()
                    .environmentObject(appState)
            } else {
                ContentView()
                    .environmentObject(appState)
            }
        }
    }
}
