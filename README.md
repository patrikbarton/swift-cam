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


## 📂 Project Highlights: A Code-Level Look

This section dives into specific files that are central to the project's architecture and contain its most interesting technical implementations. 

### 1. `LiveCameraViewModel.swift`

**This is the brain of the entire live camera experience.** It's a perfect example of a complex `ObservableObject` that manages real-time data streams while safely interacting with the UI.

-   **What to look for:** The `AVCaptureVideoDataOutputSampleBufferDelegate` extension at the bottom of the file.
-   **The `captureOutput(...)` method** is the entry point for every frame that comes from the camera. It runs on a `nonisolated` background queue provided by AVFoundation.
-   **Concurrency Bridge**: Inside `captureOutput`, a `Task` is created. This is the critical bridge from the old, delegate-based world to the new world of Swift Concurrency. 
-   **Thread-Safe State Checking**: The first thing the `Task` does is `await MainActor.run { ... }` to hop to the main thread and safely check UI state like `isProcessing` and the throttling timer. This prevents data races.
-   **Delegation of Work**: After a frame is approved for processing, the ViewModel doesn't do the heavy lifting itself. It delegates the work to other services in parallel:
    -   It calls `visionService.performClassification(...)` to run the ML model.
    -   It calls `updateUIPreviews(...)` to handle the face blur and low-res preview generation.
-   **Publishing Results**: Once `visionService` returns results, the ViewModel hops back to the main thread with `await MainActor.run { ... }` to update the `@Published var liveResults`, which the SwiftUI view is subscribed to.

### 2. `VisionService.swift`

**This is the heart of the AI engine and the core of our performance strategy.** It's implemented as a Swift `actor` to guarantee that its internal state (the model caches) is accessed in a thread-safe manner.

-   **What to look for:** The `performClassification(...)` public function and the `getClassificationRequest(...)` private function.
-   **Clean API**: The `performClassification` function provides a simple, `async` API to the rest of the app. It hides all the underlying complexity of the Vision framework.
-   **The Caching Strategy**: The `getClassificationRequest` method demonstrates the crucial performance optimization. It maintains two dictionaries:
    1.  `visionModelCache`: Caches the `VNCoreMLModel`, which is the compiled model that's expensive to load from disk.
    2.  `requestCache`: Caches the `VNCoreMLRequest`. This was the key to solving the ANE power-cycling issue, as it prevents the system from re-configuring the hardware pipeline for every single frame.

### 3. `AppStateViewModel.swift`

**This is the app's single source of truth for all user settings.** It demonstrates a clean pattern for managing and persisting global state.

-   **What to look for:** The `@Published` properties with `didSet` observers.
-   **Automatic Persistence**: When a user changes a setting in the UI (like enabling face blur), the `didSet` property observer is triggered. This observer immediately writes the new value to `UserDefaults`.
    ```swift
    @Published var faceBlurringEnabled: Bool = false {
        didSet { UserDefaults.standard.set(faceBlurringEnabled, forKey: Keys.faceBlur) }
    }
    ```
-   **Loading on Init**: In the `init()` method, the ViewModel loads all the saved values from `UserDefaults`, ensuring user preferences are restored every time the app launches.

### 4. `FaceBlurringService.swift`

**A great, self-contained example of combining multiple Apple frameworks (Vision and Core Image).**

-   **What to look for:** The `blurFaces(...)` method.
-   **The Pipeline**:
    1.  It creates a `VNDetectFaceRectanglesRequest` (a Vision request specifically for finding faces).
    2.  It runs this request on the input image.
    3.  It iterates through the results (`VNFaceObservation`).
    4.  For each face's bounding box, it creates and applies a `CIFilter` (like `CIPixellate` or `CIGaussianBlur`) to that specific region of the image.
    5.  It composites the blurred face regions back onto the original image and returns the result.

### 5. `SettingsTabView.swift`

**This file shows how a complex, data-driven UI is built in SwiftUI.**

-   **What to look for:** How it uses `@ObservedObject var appStateViewModel: AppStateViewModel`.
-   **Declarative UI**: The view is a direct reflection of the state in `AppStateViewModel`. There is no manual code to update the UI.
-   **Direct Binding**: SwiftUI components are bound directly to the ViewModel's `@Published` properties. For example, the "Blur Faces" toggle is bound with `$appStateViewModel.faceBlurringEnabled`. When the user taps the toggle, the ViewModel's property is updated directly, which in turn triggers the `didSet` to save the value to `UserDefaults`.

### 6. `Logger+Extensions.swift`

**A simple but powerful utility that was key to solving our concurrency warnings.**

-   **What to look for:** The `nonisolated static let` properties.
-   **The Problem**: A standard `static let logger = Logger(...)` is isolated to the Main Actor by default. Calling it from a background thread (like our camera queue) would produce a compiler warning.
-   **The Solution**: By declaring the logger as `nonisolated`, we tell the Swift compiler that it is safe to use from any thread or actor. Since Apple's `Logger` is designed to be thread-safe, this is a correct and elegant way to enable unified logging across the entire app.
