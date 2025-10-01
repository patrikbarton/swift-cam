# 📸 Swift-Cam

AI-powered object recognition app for iOS using Core ML.

## Features

- 🤖 **Multiple ML Models**: MobileNet V2, ResNet-50, and FastViT
- 📷 **Live Camera**: Real-time object detection
- 🖼️ **Photo Library**: Analyze saved images
- ⚡ **Fast Preloading**: Models loaded during splash screen
- 🎨 **Modern UI**: Clean, Apple-style interface

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
   Or see [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) for manual setup.

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

- **[Developer Setup Guide](DEVELOPER_SETUP.md)** - Configure code signing (required for first-time setup)
- **[Repository Structure](REPOSITORY_STRUCTURE.md)** - What files to commit, Info.plist explained
- **[Quick Start](QUICK_START.md)** - TL;DR for getting started quickly
- **[Docs/](Docs/)** - Additional technical guides and design documentation
  - [Repository Q&A](Docs/REPOSITORY_QUESTIONS_ANSWERED.md) - Common questions answered
  - [Testing Guide](Docs/TESTING_GUIDE.md) - How to test the app
  - [Design Docs](Docs/) - Camera, UI, and ML implementation details

## 🏗️ Architecture

```
swift-cam/
├── ModelPreloader.swift      # Preloads ML models at launch
├── SplashScreenView.swift    # Splash with progress tracking
├── ContentView.swift         # Main app UI and logic
├── swift_camApp.swift        # App entry point
└── *.mlmodel[c]             # Core ML models
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
- See [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) for details

## 📦 ML Models

The app includes three pre-compiled Core ML models:
- **MobileNetV2**: Efficient and fast
- **ResNet-50**: High accuracy
- **FastViT**: Vision Transformer architecture

Models are automatically compiled by Xcode during build and preloaded during the splash screen for optimal performance.

## 🐛 Troubleshooting

### Signing Issues
See [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) troubleshooting section.

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

**Need help?** Check [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) or open an issue!
