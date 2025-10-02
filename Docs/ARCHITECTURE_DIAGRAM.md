# Architektur-Diagramm - swift-cam

##  System-Architektur

```
┌─────────────────────────────────────────────────────────────────────┐
│                          swift-cam App                               │
│                     (MVVM Architecture)                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         📱 PRESENTATION LAYER                        │
│                              (Views)                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │   ContentView    │  │  LiveCameraView  │  │ SplashScreenView │  │
│  │   (Main UI)      │  │  (Live Camera)   │  │  (Startup)       │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│           │                     │                      │             │
│           └─────────────────────┴──────────────────────┘             │
│                                 │                                    │
│  ┌──────────────────────────────┴──────────────────────────────┐   │
│  │              UI Components (Reusable)                        │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │ • ModernImagePreviewView      • ModernResultsList           │   │
│  │ • ModernClassificationRow     • AppleStyleButton            │   │
│  │ • ModernConfidenceBadge       • ModernErrorView             │   │
│  │ • ModernEmptyResultsView      • ModernLiveResultsOverlay    │   │
│  │ • NativeCameraView                                           │   │
│  └──────────────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            │ @StateObject / @ObservedObject
                            │ Bindings & Actions
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        🧠 BUSINESS LOGIC LAYER                       │
│                           (ViewModels)                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐  ┌────────────────────┐  ┌─────────────────┐ │
│  │ CameraViewModel  │  │LiveCameraViewModel │  │AppStateViewModel│ │
│  │ @MainActor       │  │  @MainActor        │  │  @MainActor     │ │
│  │ ObservableObject │  │  ObservableObject  │  │ ObservableObject│ │
│  ├──────────────────┤  ├────────────────────┤  ├─────────────────┤ │
│  │ • classifyImage()│  │ • startSession()   │  │ • preloadModels │ │
│  │ • loadModel()    │  │ • stopSession()    │  │ • isLoading     │ │
│  │ • updateModel()  │  │ • updateModel()    │  │ • progress      │ │
│  │ • clearImage()   │  │ • liveResults      │  │                 │ │
│  └────────┬─────────┘  └────────┬───────────┘  └────────┬────────┘ │
│           │                     │                        │           │
│           └─────────────────────┴────────────────────────┘           │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            │ Service Calls
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         ⚙️  SERVICE LAYER                            │
│                        (Business Services)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────┐      ┌──────────────────────────┐    │
│  │     ModelService         │      │     CameraService        │    │
│  │     (Singleton)          │      │     (Session Manager)    │    │
│  ├──────────────────────────┤      ├──────────────────────────┤    │
│  │ • createModel()          │      │ • setupSession()         │    │
│  │ • Model Caching          │      │ • startSession()         │    │
│  │ • Compute Unit Detection │      │ • stopSession()          │    │
│  │ • Neural Engine Fallback │      │ • AVCaptureSession       │    │
│  └────────────┬─────────────┘      └────────────┬─────────────┘    │
│               │                                  │                   │
└───────────────┼──────────────────────────────────┼───────────────────┘
                │                                  │
                ▼                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        📊 DATA LAYER                                 │
│                      (Models & Data)                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐  ┌────────────────────┐  ┌─────────────┐ │
│  │   MLModelType        │  │ClassificationResult│  │AppConstants │ │
│  │   (Enum)             │  │    (Struct)        │  │  (Enum)     │ │
│  ├──────────────────────┤  ├────────────────────┤  ├─────────────┤ │
│  │ • mobileNet          │  │ • identifier       │  │ • maxResults│ │
│  │ • resnet50           │  │ • confidence       │  │ • animation │ │
│  │ • fastViT            │  │ • detectedAt       │  │ • heights   │ │
│  │ • displayName        │  │ • displayName      │  │             │ │
│  │ • icon               │  │ • confidenceColor  │  │             │ │
│  └──────────────────────┘  └────────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        🔧 UTILITIES LAYER                            │
├─────────────────────────────────────────────────────────────────────┤
│  • Logger+Extensions        • UIImage+Extensions                    │
│  • ConditionalLogger        • UIImage.Orientation Extensions        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                          ERROR LAYER                                │
├─────────────────────────────────────────────────────────────────────┤
│  • ImageLoadingError        • ModelLoadingError                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        🤖 EXTERNAL FRAMEWORKS                        │
├─────────────────────────────────────────────────────────────────────┤
│  • CoreML           • Vision          • AVFoundation                │
│  • SwiftUI          • PhotosUI        • Combine                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 🔄 Datenfluss-Diagramm

### Bildklassifizierung Flow

```
┌─────────────┐
│    User     │
│   Action    │
└──────┬──────┘
       │
       │ 1. User wählt Bild
       ▼
┌─────────────┐
│ ContentView │
│   (View)    │
└──────┬──────┘
       │
       │ 2. Bindet Action an ViewModel
       ▼
┌───────────────────┐
│ CameraViewModel   │
│                   │
│ classifyImage()   │
└──────┬────────────┘
       │
       │ 3. Ruft Service auf
       ▼
┌───────────────────┐
│  ModelService     │
│                   │
│ createModel()     │
└──────┬────────────┘
       │
       │ 4. Lädt ML-Model
       ▼
┌───────────────────┐
│  CoreML/Vision    │
│  (Framework)      │
└──────┬────────────┘
       │
       │ 5. Inference durchführen
       ▼
┌───────────────────┐
│ClassificationResult│
│    (Model)        │
└──────┬────────────┘
       │
       │ 6. Ergebnis zurück
       ▼
┌───────────────────┐
│ CameraViewModel   │
│ @Published results│
└──────┬────────────┘
       │
       │ 7. UI-Update via Binding
       ▼
┌─────────────────────────┐
│ ModernResultsList       │
│ (View Component)        │
└─────────────────────────┘
```

##  Modul-Abhängigkeiten

```
Views
  ├─ ViewModels (dependency)
  └─ Models (dependency)

ViewModels
  ├─ Services (dependency)
  ├─ Models (dependency)
  └─ Utilities (dependency)

Services
  ├─ Models (dependency)
  ├─ Utilities (dependency)
  └─ External Frameworks (CoreML, Vision)

Models
  └─ (No dependencies - pure data)

Utilities
  └─ (Minimal dependencies)

Errors
  └─ (No dependencies)
```

##  Architektur-Prinzipien

### 1. **Unidirectional Data Flow**
```
View → ViewModel → Service → Model
       ↑                        │
       └────── @Published ──────┘
```

### 2. **Dependency Injection**
```swift
// Services als Singletons injiziert
class CameraViewModel {
    private let modelService = ModelService.shared
}
```

### 3. **Protocol-Oriented (zukünftig)**
```swift
protocol ModelServiceProtocol {
    func createModel(for type: MLModelType) async -> VNCoreMLRequest?
}

// Ermöglicht Mock-Testing
class MockModelService: ModelServiceProtocol { }
```

##  Skalierbarkeit

Die modulare Architektur ermöglicht:

1. **Neue Features hinzufügen**
   - Neues ViewModel → Neue Business-Logik
   - Neue View → Neue UI
   - Neuer Service → Neue Shared-Funktionalität

2. **Testing erweitern**
   - Unit Tests für ViewModels
   - UI Tests für Views
   - Integration Tests für Services

3. **Code wiederverwenden**
   - UI-Components in anderen Views
   - Services in anderen ViewModels
   - Models app-weit

4. **Team-Entwicklung**
   - Parallelarbeit an verschiedenen Layern
   - Klare Verantwortlichkeiten
   - Weniger Merge-Konflikte

---

**Architektur**: MVVM mit klarer Layer-Trennung  
**Pattern**: Separation of Concerns, Single Responsibility, Dependency Injection

