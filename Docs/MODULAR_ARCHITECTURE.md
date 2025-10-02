# Modulare Architektur - swift-cam

## Übersicht

Die App wurde von einem Monolithen (1643 Zeilen in einer Datei) in eine saubere, modulare MVVM-Architektur umstrukturiert. Die Trennung von UI und Logik ermöglicht bessere Wartbarkeit, Testbarkeit und Skalierbarkeit.

## Architektur-Pattern: MVVM (Model-View-ViewModel)

### 🎯 Designprinzipien

1. **Separation of Concerns**: UI-Code ist strikt von Business-Logik getrennt
2. **Single Responsibility**: Jede Komponente hat eine klare, fokussierte Aufgabe
3. **Dependency Injection**: Services werden injiziert, nicht hart kodiert
4. **Reusability**: UI-Komponenten sind wiederverwendbar und unabhängig
5. **Testability**: ViewModels und Services können isoliert getestet werden

## 📁 Projektstruktur

```
swift-cam/
├── Models/                          # 📊 Datenmodelle
│   ├── MLModelType.swift           # ML-Model Enumeration
│   ├── ClassificationResult.swift  # Klassifizierungsergebnis-Modell
│   └── AppConstants.swift          # App-weite Konstanten
│
├── ViewModels/                      # 🧠 Business-Logik
│   ├── CameraViewModel.swift       # Kamera & Klassifizierungs-Logik
│   ├── LiveCameraViewModel.swift   # Live-Kamera-Logik
│   └── AppStateViewModel.swift     # App-Status & Splash-Screen-Logik
│
├── Services/                        # ⚙️ Business Services
│   ├── ModelService.swift          # ML-Model Loading & Caching
│   └── CameraService.swift         # Kamera-Session-Management
│
├── Views/                           # 🎨 UI-Komponenten
│   ├── Main/
│   │   ├── ContentView.swift       # Haupt-UI (nur UI, keine Logik!)
│   │   └── LiveCameraView.swift    # Live-Kamera-UI
│   ├── Components/                  # Wiederverwendbare UI-Komponenten
│   │   ├── ModernImagePreviewView.swift
│   │   ├── ModernClassificationResultsView.swift
│   │   ├── ModernResultsList.swift
│   │   ├── ModernClassificationRow.swift
│   │   ├── AppleStyleButton.swift
│   │   ├── ModernConfidenceBadge.swift
│   │   ├── ModernErrorView.swift
│   │   ├── ModernEmptyResultsView.swift
│   │   ├── ModernLiveResultsOverlay.swift
│   │   └── NativeCameraView.swift
│   └── Splash/
│       └── SplashScreenView.swift  # Splash-Screen-UI
│
├── Utilities/                       # 🔧 Hilfsfunktionen & Extensions
│   ├── Logger+Extensions.swift     # Logging-Utilities
│   └── UIImage+Extensions.swift    # UIImage-Extensions
│
├── Errors/                          # ❌ Error-Typen
│   ├── ImageLoadingError.swift     # Bild-Lade-Fehler
│   └── ModelLoadingError.swift     # Model-Lade-Fehler
│
└── swift_camApp.swift              # App-Einstiegspunkt
```

## 🔄 Datenfluss (MVVM)

```
┌─────────────┐
│    View     │  (SwiftUI Views - nur UI)
│  (UI Only)  │
└──────┬──────┘
       │ @StateObject / @ObservedObject
       │ Bindings & Actions
       ▼
┌─────────────┐
│  ViewModel  │  (Business Logic)
│ (ObservableObject) │
│  @Published │
└──────┬──────┘
       │ Calls Services
       │
       ▼
┌─────────────┐
│  Service    │  (Shared Services)
│  (Singleton) │
└──────┬──────┘
       │ Works with Models
       │
       ▼
┌─────────────┐
│   Model     │  (Data & Business Entities)
│  (Struct)   │
└─────────────┘
```

## 📦 Layer-Beschreibung

### 1. **Models/** - Datenmodelle

**Zweck**: Reine Datenstrukturen ohne Logik

- `MLModelType`: Enumeration aller verfügbaren ML-Modelle
- `ClassificationResult`: Struktur für Klassifizierungsergebnisse
- `AppConstants`: Zentrale Konstanten

**Eigenschaften**:
- ✅ Immutable (wenn möglich)
- ✅ Keine UI-Abhängigkeiten
- ✅ Keine Business-Logik

### 2. **ViewModels/** - Business-Logik

**Zweck**: Vermittler zwischen View und Model, enthält Business-Logik

#### `CameraViewModel`
- Verwaltet Bildklassifizierung
- Koordiniert Model-Loading
- Published States für UI-Binding
- **Keine UI-Imports!**

#### `LiveCameraViewModel`
- Verwaltet Live-Kamera-Feed
- Echtzeit-Klassifizierung
- Objekt-Tracking

#### `AppStateViewModel`
- App-Initialisierung
- Model-Preloading
- Splash-Screen-Status

**Eigenschaften**:
- ✅ `@MainActor` für UI-Updates
- ✅ `ObservableObject` für SwiftUI-Binding
- ✅ `@Published` Properties für State
- ✅ Nutzt Services via Dependency Injection

### 3. **Services/** - Shared Services

**Zweck**: Wiederverwendbare, zustandslose Business-Services

#### `ModelService`
- ML-Model Loading
- Model Caching
- Compute-Unit-Management
- **Singleton Pattern**

#### `CameraService`
- AVCaptureSession Management
- Kamera-Setup
- Session-Control

**Eigenschaften**:
- ✅ Singleton (`.shared`)
- ✅ Zustandslos (stateless)
- ✅ Wiederverwendbar

### 4. **Views/** - UI-Komponenten

**Zweck**: Reine UI-Darstellung ohne Business-Logik

#### Main Views
- `ContentView`: Haupt-UI mit View-Composition
- `LiveCameraView`: Live-Kamera-Interface

#### Components (Wiederverwendbar)
- Atomare UI-Komponenten
- Keine Business-Logik
- Props-basiert

**Eigenschaften**:
- ✅ Nur UI-Code
- ✅ Nutzt ViewModels via `@StateObject`/`@ObservedObject`
- ✅ Props für Konfiguration
- ✅ Keine direkten Service-Aufrufe

### 5. **Utilities/** - Hilfsfunktionen

**Zweck**: Gemeinsame Utilities und Extensions

- Logger-Extensions
- UIImage-Extensions
- Conditional Logging

### 6. **Errors/** - Error-Typen

**Zweck**: Zentrale Error-Definitionen

- `ImageLoadingError`
- `ModelLoadingError`

## 🎯 Vorteile der Modularisierung

### Vorher (Monolith)
```
ContentView.swift: 1643 Zeilen
├── UI-Code
├── Business-Logik
├── ML-Model-Management
├── Kamera-Management
├── Extensions
├── Helper-Funktionen
└── Alles vermischt! 😱
```

### Nachher (Modular)
```
28 Dateien, durchschnittlich ~100-200 Zeilen
├── Klare Verantwortlichkeiten
├── Einfaches Testing
├── Bessere Wartbarkeit
├── Wiederverwendbare Komponenten
└── Saubere Architektur! ✨
```

## 🔧 Verwendung

### ViewModel in View verwenden

```swift
struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        // UI bindet an ViewModel-Properties
        if viewModel.isAnalyzing {
            ProgressView()
        }
        
        Button("Classify") {
            // View ruft ViewModel-Methoden auf
            Task {
                await viewModel.classifyImage(image)
            }
        }
    }
}
```

### Service in ViewModel verwenden

```swift
class CameraViewModel: ObservableObject {
    private let modelService = ModelService.shared
    
    func loadModel(_ type: MLModelType) async {
        // ViewModel nutzt Service
        let model = await modelService.createModel(for: type)
        // ...
    }
}
```

### Komponenten komponieren

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            ModernImagePreviewView(image: image, isAnalyzing: false)
            ModernClassificationResultsView(results: results)
            AppleStyleButton(title: "Scan", style: .primary)
        }
    }
}
```

## 🧪 Testing-Strategie

### Unit Tests
- **ViewModels**: Business-Logik isoliert testen
- **Services**: Service-Methoden isoliert testen
- **Models**: Datenvalidierung testen

### UI Tests
- **Views**: UI-Interaktionen mit Mock-ViewModels
- **Integration**: End-to-End-Tests

### Beispiel: ViewModel Test
```swift
@MainActor
class CameraViewModelTests: XCTestCase {
    var viewModel: CameraViewModel!
    
    override func setUp() {
        viewModel = CameraViewModel()
    }
    
    func testImageClassification() async {
        let testImage = UIImage(/* ... */)
        await viewModel.classifyImage(testImage)
        
        XCTAssertFalse(viewModel.isAnalyzing)
        XCTAssertNotNil(viewModel.classificationResults)
    }
}
```

## 📚 Best Practices

### ✅ DO's
- Halte Views dünn (nur UI)
- Logik in ViewModels
- Services für wiederverwendbare Funktionalität
- Nutze `@Published` für UI-bindbare States
- Dependency Injection verwenden
- Props für View-Konfiguration

### ❌ DON'Ts
- Keine Business-Logik in Views
- Keine UI-Imports in ViewModels
- Keine direkten Service-Aufrufe in Views
- Keine Singletons in ViewModels (außer Services)
- Keine globalen States

## 🚀 Migration von Alt zu Neu

Falls du neuen Code hinzufügst:

1. **Model hinzufügen** → `Models/`
2. **Business-Logik** → `ViewModels/`
3. **Shared Services** → `Services/`
4. **UI-Komponente** → `Views/Components/`
5. **Utilities** → `Utilities/`

## 📖 Weiterführende Ressourcen

- [Apple MVVM Guide](https://developer.apple.com/documentation/swiftui)
- [SwiftUI Best Practices](https://www.hackingwithswift.com/quick-start/swiftui)
- [Clean Architecture in Swift](https://www.raywenderlich.com/8477-clean-architecture-tutorial-for-ios)

---

**Erstellt**: 2. Oktober 2025  
**Architektur**: MVVM (Model-View-ViewModel)  
**Pattern**: Separation of Concerns, Single Responsibility, Dependency Injection

