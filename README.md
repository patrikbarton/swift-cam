# 📸 AI Vision: Intelligent Camera for iOS

AI Vision is more than just a camera app—it's a powerful, real-time object recognition engine built with modern Swift and SwiftUI. It leverages on-device machine learning to understand the world around you, offering intelligent features that make capturing the perfect shot easier than ever.

This project serves as a showcase for cutting-edge iOS development, combining a fluid user experience with a highly performant, concurrency-safe architecture.

---

## ✨ Core Features

*   🤖 **Multiple AI Models**: Instantly switch between high-speed (MobileNetV2), high-accuracy (ResNet50), and state-of-the-art (FastViT) models.
*   🎯 **Live Object Highlighting**: Get a visual confirmation with a glowing border when a desired object is in frame.
*   🏆 **Best Shot Mode**: Let the AI be your photographer! It automatically captures high-resolution photos when it detects a specific object with high confidence.
*   💡 **Assisted Capture**: A semi-automatic mode that only enables the shutter when a highlighted object is detected, helping you capture perfectly-timed photos.
*   🖼️ **Photo Library Analysis**: Run any image from your photo library through the AI engine.
*   🔒 **Privacy-First Face Blurring**: Automatically detect and blur faces in both the live camera feed and saved photos, with multiple blur styles (Gaussian, Pixelated, Black Box).
*   ⚙️ **Rich, Persistent Settings**: From the AI model to privacy rules and camera modes, your preferences are automatically saved and restored on launch.


## 🏗️ Architecture: A Deep Dive

This app is built using a modern, decoupled architecture designed for performance, scalability, and thread safety. It's a great example of how to structure a complex, real-time application in SwiftUI.

```
┌───────────────────────────────────────────────────────────┐
│                          UI Layer (Views)                   │
│      (SwiftUI, Feature-Specific Component Folders)        │
└───────────────────────────────────────────────────────────┘
                           ▲
                           │ Binds to & Displays Data
                           ▼
┌───────────────────────────────────────────────────────────┐
│                  State Layer (ViewModels)                 │
│ (MVVM, @MainActor, AppStateViewModel, LiveCameraViewModel)│
└───────────────────────────────────────────────────────────┘
                           ▲
                           │ Calls Functions
                           ▼
┌───────────────────────────────────────────────────────────┐
│                 Business Logic (Services)                 │
│   (Actors, VisionService, ModelService, FaceBlurService)  │
└───────────────────────────────────────────────────────────┘
```

### 1. UI Layer: SwiftUI Views

The entire user interface is built with **SwiftUI**. The `View` layer is kept simple and is responsible only for displaying data and forwarding user actions to the ViewModels.

-   **Tab-Based Navigation**: The app is organized into three main tabs: `Home`, `Camera`, and `Settings`.
-   **Feature-Specific Components**: To keep the codebase organized, reusable components are grouped by the feature they belong to (e.g., `Views/Camera/Components/`). This makes the code easier to navigate than a single, monolithic `Components` folder.

### 2. State Layer: MVVM with ViewModels

We use the **Model-View-ViewModel (MVVM)** pattern to separate UI from logic. ViewModels are classes that hold the state for a given view and handle user interactions.

-   `AppStateViewModel`: The **single source of truth** for global settings. It loads and saves all user preferences (like the selected model, privacy settings, etc.) to `UserDefaults` and provides them to the rest of the app.
-   `LiveCameraViewModel`: The brain of the live camera experience. It manages the camera session, processes frames, and coordinates all the AI features.
-   `HomeViewModel`: Manages the state for the "Home" tab, handling image selection from the Photo Library and running classification on still images.

### 3. Business Logic: The Service Layer

Services are responsible for discrete units of work and are decoupled from the UI, making them highly reusable and testable.

-   `VisionService`: The heart of the AI engine. It's a Swift **Actor**, ensuring that all its operations are thread-safe. It handles everything related to Core ML and the Vision framework.
-   `ModelService`: Responsible for loading the raw `.mlmodel` files from disk.
-   `FaceBlurringService`: A dedicated service for detecting and blurring faces in an image.
-   `PhotoSaverService`: A simple utility to handle saving images to the device's photo library.

### 4. Concurrency Model: Performance & Safety

This is one of the most important architectural aspects of the project. The app is designed to be fully **concurrency-safe** using modern Swift Concurrency.

-   **Main Actor for UI**: All ViewModels and Views are marked with `@MainActor`, guaranteeing that all UI updates happen on the main thread. This prevents crashes and visual glitches.
-   **Background Processing**: The `AVCaptureSession` delegate methods, which deliver camera frames, run on a dedicated background queue. This ensures the UI remains smooth and responsive (60fps) even while the camera is active.
-   **`nonisolated` for Performance**: Camera-related properties in the `LiveCameraViewModel` are marked as `nonisolated` to explicitly separate them from the Main Actor's state, allowing them to be safely managed on the background queue.
-   **`async/await` and Structured Concurrency**: We use `Task` and `async/await` to bridge between the background camera queue and our application logic, ensuring there are no data races. This modern approach replaces complex completion handler closures.

### 5. ML Model Management: Efficiency is Key

To ensure the app is fast and responsive, especially when switching between AI models, we use an intelligent caching strategy.

-   **Pre-warming**: On app launch, all ML models are loaded into memory during the splash screen. This prevents any "first-use" lag.
-   **Efficient Caching (`VisionService`)**: The `VisionService` actor maintains a cache for both the compiled `VNCoreMLModel` and the `VNCoreMLRequest` objects.
-   **Solving ANE Power-Cycling**: By caching the `VNCoreMLRequest`, we prevent the Apple Neural Engine (ANE) from being powered on and off every time the model is used. This was a key performance optimization that resolved significant system-level overhead during live detection.

---

## 🚀 How to Build

1.  **Clone the repository**.
2.  **Configure Developer Settings**: Run the setup script to create your developer configuration file. This is only needed once.
    ```bash
    ./setup-developer.sh
    ```
3.  **Open `swift-cam.xcodeproj` in Xcode** and build!


## 📂 Project Highlights (For Presentation)

If you want to showcase the core logic of the project, these files are the best place to start:

-   `LiveCameraViewModel.swift`: See the `captureOutput` delegate method for the entry point of our real-time frame processing. Notice how it uses `Task` and `await MainActor.run` to safely interact with the UI and services from a background thread.
-   `VisionService.swift`: This **Actor** is the heart of the ML implementation. Look at `performClassification` to see the streamlined Vision pipeline and `getClassificationRequest` to see the efficient caching strategy.
-   `Logger+Extensions.swift`: Shows how to create app-wide, thread-safe loggers using the `nonisolated` keyword.
-   `SettingsTabView.swift`: A great example of a complex, data-driven settings screen built entirely in SwiftUI and bound to a central state object (`AppStateViewModel`).
