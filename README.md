# 📸 Swift-Cam

AI-powered object recognition app for iOS using Core ML.

## ✨ Features

-   🤖 **Multiple ML Models**: Switch between MobileNetV2, ResNet-50, and FastViT.
-   📷 **Live Object Highlighting**: Get a visual confirmation with a green border when a desired object is in frame.
-   🎯 **Best Shot Mode**: Let the AI automatically capture high-resolution photos when it detects a specific object over a set period.
-   💡 **Assisted Capture**: A semi-automatic mode that only enables the shutter when a highlighted object is detected, helping you take perfectly-timed photos.
-   🖼️ **Photo Library Analysis**: Analyze any image from your photo library.
-   ⚙️ **Rich Settings**: All AI-assisted features are fully configurable in the app's settings menu.
-   💾 **Persistent Choices**: Your preferred model and settings are saved and restored automatically.
-   🔒 **Privacy Focused**: Includes an option to automatically blur faces in photos.

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Apple Developer account

### First-Time Setup

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd swift-cam
   ```

2. **Configure developer settings:**
   ```bash
   ./setup-developer.sh
   ```
   Or see [DEVELOPER_SETUP.md](Docs/DEVELOPER_SETUP.md) for manual setup.

3. **Open in Xcode:**
   ```bash
   open swift-cam.xcodeproj
   ```

4. **Build and run!** 🎉

**Note:** Camera and Photo Library permissions are already configured in the project. No additional Info.plist setup needed!

### For Returning Developers

Just pull and work - your developer settings are preserved:
```bash
git pull
# No reconfiguration needed!
```

## 📖 Documentation

- **[Developer Setup Guide](Docs/DEVELOPER_SETUP.md)** - Configure code signing (required for first-time setup)
- **[Repository Structure](Docs/REPOSITORY_STRUCTURE.md)** - What files to commit, Info.plist explained
- **[Quick Start](Docs/QUICK_START.md)** - TL;DR for getting started quickly
- **[Docs/](Docs/)** - Additional technical guides and design documentation
  - [Repository Q&A](Docs/REPOSITORY_QUESTIONS_ANSWERED.md) - Common questions answered
  - [Testing Guide](Docs/TESTING_GUIDE.md) - How to test the app
  - [Design Docs](Docs/) - Camera, UI, and ML implementation details

## 🏗️ Architecture

This app uses a modern MVVM-inspired architecture designed for SwiftUI.

-   **Views**: The UI is built with pure SwiftUI. `ContentView` is the entry point, containing a `TabView` for the main sections.
-   **ViewModels**:
    -   `AppStateViewModel`: The single source of truth for global UI state and user-configurable settings. All settings are persisted to `UserDefaults`.
    -   `LiveCameraViewModel`: Manages the entire live camera session, including device management, running the Vision ML model, and implementing all AI-assisted features (Highlighting, Best Shot, Assisted Capture).
    -   `HomeViewModel`: Manages the state for the "Home" tab, specifically the logic for picking and analyzing an image from the user's Photo Library.
-   **Services**:
    -   `ModelService`: A singleton responsible for efficiently loading and caching Core ML models and their class labels.
    -   `FaceBlurringService`: A utility service for detecting and blurring faces in images.

```
swift-cam/
├── Views/
│   ├── Main/              # Main screens (ContentView, LiveCameraView)
│   └── Components/        # Reusable UI components
├── ViewModels/
│   ├── AppStateViewModel.swift
│   ├── LiveCameraViewModel.swift
│   └── HomeViewModel.swift
├── Services/
│   ├── ModelService.swift
│   └── FaceBlurringService.swift
├── Models/                # Simple data structures
└── Utilities/             # Helpers and extensions
```

## 🤝 Contributing

1. Clone the repo
2. Run `./setup-developer.sh` to configure your signing
3. Create a feature branch
4. Make your changes
5. Commit and push
6. Create a pull request

Your personal developer configuration (`DeveloperSettings.xcconfig`) won't be committed - each developer has their own.

## 🔒 Code Signing

This project uses per-developer configuration files to avoid signing conflicts:
- Each developer has their own `DeveloperSettings.xcconfig` (git-ignored)
- No more merge conflicts on Team IDs or Bundle Identifiers
- See [DEVELOPER_SETUP.md](Docs/DEVELOPER_SETUP.md) for details

## 📦 ML Models

The app includes three pre-compiled Core ML models:
- **MobileNetV2**: Efficient and fast
- **ResNet-50**: High accuracy
- **FastViT**: Vision Transformer architecture

Models are automatically compiled by Xcode during build and preloaded during the splash screen for optimal performance.

## 🐛 Troubleshooting

### Signing Issues
See [DEVELOPER_SETUP.md](Docs/DEVELOPER_SETUP.md) troubleshooting section.

### Build Errors
1. Clean build folder: `Cmd+Shift+K`
2. Check your `DeveloperSettings.xcconfig` exists
3. Verify you're logged into Xcode with your Apple ID

### Models Not Loading
Models are automatically included in the build. If you see errors:
1. Check the `.mlmodel` and `.mlpackage` files are in `swift-cam/` folder
2. Clean and rebuild the project

## 📄 License

[Your License Here]

## 👥 Authors

- Joshua Nöldeke
- [Contributors]

---

**Need help?** Check [DEVELOPER_SETUP.md](Docs/DEVELOPER_SETUP.md) or open an issue!