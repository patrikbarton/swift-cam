# 🎨 Xcode Previews Guide

## ✅ All Files Now Have Previews!

Every view in your app now has SwiftUI previews for rapid development and testing!

## 📱 Available Previews

### 1. **swift_camApp.swift**
No preview needed - it's the app entry point.

### 2. **SplashScreenView.swift**
```swift
#Preview {
    SplashScreenView()
        .environmentObject(AppState())
}
```
**Shows:** Full splash screen with logo and loading animation

---

### 3. **ContentView.swift** (9 Previews!)

#### Main View:
```swift
#Preview {
    ContentView()
}
```
**Shows:** Full main app interface

#### Component Previews:

**FAB Menu:**
```swift
#Preview("FAB Menu") { ... }
```
Shows the floating action button menu expanded

**Image Preview States:**
```swift
#Preview("Modern Image Preview - With Image") { ... }
#Preview("Modern Image Preview - Analyzing") { ... }
```
Shows image display with and without loading spinner

**Results States:**
```swift
#Preview("Classification Results") { ... }
#Preview("Error State") { ... }
#Preview("Empty State") { ... }
```
Shows different result states (success, error, empty)

---

### 4. **LiveCameraView.swift** (3 Previews!)

#### Main View:
```swift
#Preview {
    @Previewable @State var selectedModel = MLModelType.mobileNet
    LiveCameraView(
        cameraManager: CameraManager(),
        selectedModel: $selectedModel
    )
}
```
**Shows:** Full live camera interface (camera won't work in preview, but UI will)

#### Component Previews:

**Zoom Buttons:**
```swift
#Preview("Zoom Button - Active") { ... }
#Preview("Zoom Button - Inactive") { ... }
```
Shows zoom button in active/inactive states

---

### 5. **PhotoLibraryManager.swift**
No preview - This is a manager class with no UI

### 6. **SharedModels.swift**
No preview - These are data models with no UI

---

## 🚀 How to Use Previews in Xcode

### Open Preview Canvas:
1. **Keyboard:** Press `⌥⌘↩` (Option-Command-Return)
2. **Menu:** Editor → Canvas
3. **Button:** Click "Canvas" in the top-right of Xcode

### Navigate Between Previews:
When a file has multiple previews, use the dropdown menu at the bottom of the preview canvas to switch between them!

### Preview Controls:
- **▶️ Live Preview:** Makes the preview interactive
- **🔄 Refresh:** Rebuilds the preview
- **📱 Device Selector:** Change device/orientation
- **🎨 Color Scheme:** Toggle light/dark mode

### Tips:
- Previews update automatically as you type
- Cmd+Click on a view to show it in preview
- Pin multiple previews to compare side-by-side
- Use preview to test dark mode instantly!

---

## 📊 Preview Count by File

| File | Preview Count | Purpose |
|------|--------------|---------|
| **ContentView.swift** | 7 | Main view + all components |
| **LiveCameraView.swift** | 3 | Live camera + zoom buttons |
| **SplashScreenView.swift** | 1 | Splash screen |
| **PhotoLibraryManager.swift** | 0 | No UI (manager class) |
| **SharedModels.swift** | 0 | No UI (data models) |
| **swift_camApp.swift** | 0 | App entry point |

**Total: 11 previews!** 🎉

---

## 🎯 Preview Benefits

### ✅ Rapid Iteration
See changes instantly without running the full app

### ✅ Component Testing
Test individual components in isolation

### ✅ Dark Mode
Toggle between light/dark instantly

### ✅ Multiple States
Preview success, error, loading, empty states side-by-side

### ✅ Device Testing
Switch between iPhone models without running simulator

### ✅ Accessibility
Test dynamic type and accessibility features

---

## 💡 Pro Tips

### 1. Multiple Previews
```swift
#Preview("Light Mode") {
    YourView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    YourView()
        .preferredColorScheme(.dark)
}
```

### 2. Preview with State
```swift
#Preview {
    @Previewable @State var value = "Hello"
    YourView(text: $value)
}
```

### 3. Preview with Sample Data
```swift
#Preview {
    YourView(items: [
        Item(name: "Sample 1"),
        Item(name: "Sample 2")
    ])
}
```

### 4. Layout Preview
```swift
#Preview(traits: .landscapeLeft) {
    YourView()
}
```

---

## 🔧 Troubleshooting

### Preview Not Showing?
1. Make sure build succeeded
2. Press `⌥⌘↩` to show canvas
3. Click refresh button in preview
4. Try Xcode → Editor → Canvas

### Preview Crashes?
1. Check for missing imports
2. Verify @Previewable syntax
3. Ensure all dependencies are available
4. Build project first (⌘B)

### Slow Previews?
1. Use simpler preview data
2. Preview components, not full views
3. Close other Xcode windows
4. Restart Xcode if needed

---

## 🎉 You're All Set!

Now you can develop UI components super fast by:
1. Opening the preview canvas
2. Making changes to your code
3. Seeing results instantly
4. Testing different states side-by-side

No more waiting for the simulator to boot! 🚀
