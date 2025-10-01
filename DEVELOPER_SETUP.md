# Developer Setup Guide

## 🎯 Purpose

This project uses a per-developer configuration file to manage code signing and bundle identifiers. This means:
- ✅ No merge conflicts on code signing settings
- ✅ Each developer uses their own Apple Developer Team ID
- ✅ Each developer can use their own bundle identifier
- ✅ No need to reconfigure Xcode after pulling changes

## 🚀 Quick Setup

### Option 1: Automated Setup (Recommended)

Run the setup script from the project root:

```bash
./setup-developer.sh
```

This will guide you through entering your Team ID and Bundle Identifier.

### Option 2: Manual Setup

1. **Copy the example configuration file:**
   ```bash
   cp swift-cam/DeveloperSettings.xcconfig.example.xcconfig swift-cam/DeveloperSettings.xcconfig
   ```

2. **Edit `swift-cam/DeveloperSettings.xcconfig`:**
   ```bash
   # Open in your preferred editor
   nano swift-cam/DeveloperSettings.xcconfig
   # or
   open -e swift-cam/DeveloperSettings.xcconfig
   ```

3. **Update the following values:**
   ```
   DEVELOPMENT_TEAM = YOUR_TEAM_ID_HERE
   PRODUCT_BUNDLE_IDENTIFIER = com.yourname.swift-cam
   ```

4. **Find your Team ID:**
   - Go to: https://developer.apple.com/account/#/membership
   - Your Team ID is shown on that page

## 📁 File Structure

```
swift-cam/
├── DeveloperSettings.xcconfig              ← Your personal config (git-ignored)
├── DeveloperSettings.xcconfig.example      ← Template (committed to git)
└── ... other files
```

## 🔒 Security

- The file `DeveloperSettings.xcconfig` is **git-ignored** 
- Your personal signing configuration will **never be committed**
- Each developer has their own configuration
- The example file shows the structure without exposing real credentials

## 🔄 Working with the Repository

### First Time Setup

1. Clone the repository
2. Run `./setup-developer.sh` or manually create your config
3. Open the project in Xcode
4. Build and run!

### Pulling Updates

When you pull updates from Git:
- ✅ Your `DeveloperSettings.xcconfig` is **preserved**
- ✅ No need to reconfigure signing in Xcode
- ✅ Just pull and continue working

### Committing Changes

When you commit:
- ✅ Your `DeveloperSettings.xcconfig` is **automatically ignored**
- ✅ Only the example file is tracked in Git
- ✅ No accidental sharing of Team IDs

## 🎨 Configuration Options

Your `DeveloperSettings.xcconfig` can include:

```
// Required settings
DEVELOPMENT_TEAM = RS5ZRK5X46                      // Your Apple Team ID
CODE_SIGN_STYLE = Automatic                        // Or Manual if you prefer
PRODUCT_BUNDLE_IDENTIFIER = com.yourname.swift-cam // Unique identifier

// Optional: Add more developer-specific settings
// MARKETING_VERSION = 1.0
// CURRENT_PROJECT_VERSION = 1
```

## 🐛 Troubleshooting

### "No signing certificate found" error

1. Make sure your `DeveloperSettings.xcconfig` exists
2. Verify your Team ID is correct
3. Check you're logged into Xcode with the correct Apple ID:
   - Xcode → Settings → Accounts

### Build fails with "Bundle identifier not found"

1. Check your `PRODUCT_BUNDLE_IDENTIFIER` in `DeveloperSettings.xcconfig`
2. Make sure it follows the format: `com.yourname.appname`
3. Ensure it matches your provisioning profile

### Changes not being applied

1. Clean the build folder: `Cmd+Shift+K` in Xcode
2. Close and reopen Xcode
3. Check the file path is correct: `swift-cam/DeveloperSettings.xcconfig`

### Xcode shows signing conflicts after pull

This shouldn't happen with the new setup, but if it does:
1. Verify your `DeveloperSettings.xcconfig` still exists
2. Check the file contents are correct
3. Try: Xcode → Product → Clean Build Folder

## 👥 Adding New Developers

When onboarding a new developer:

1. They clone the repository
2. They run `./setup-developer.sh` or copy the example file
3. They enter their own Team ID and Bundle ID
4. They're ready to work!

No coordination needed - each developer has independent configuration.

## 📝 Example Configuration

Here's what a typical `DeveloperSettings.xcconfig` looks like:

```
//
//  DeveloperSettings.xcconfig
//  swift-cam
//

// Team & Signing
DEVELOPMENT_TEAM = RS5ZRK5X46
CODE_SIGN_STYLE = Automatic

// Bundle Identifier
PRODUCT_BUNDLE_IDENTIFIER = com.joshuanoeldeke.swift-cam
```

## ✅ Checklist

Before you start working:

- [ ] `DeveloperSettings.xcconfig` exists in the `swift-cam/` folder
- [ ] Your Team ID is set correctly
- [ ] Your Bundle Identifier is unique to you
- [ ] Project builds successfully in Xcode
- [ ] `git status` doesn't show `DeveloperSettings.xcconfig` as untracked

## 🤝 Benefits

**For Individual Developers:**
- No setup conflicts
- Personal bundle identifiers
- Preserved settings across pulls

**For Teams:**
- No merge conflicts on signing
- Easy onboarding
- Consistent project structure
- Everyone can work independently

## 📚 Additional Resources

- [Xcode Build Configuration Files](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Finding Your Team ID](https://developer.apple.com/account/#/membership)

## 💡 Tips

1. **Keep your config file private** - It contains your Team ID
2. **Use descriptive bundle identifiers** - Makes testing easier
3. **Don't modify the example file** - Others use it as a template
4. **Run the setup script for new clones** - Faster than manual setup
5. **Permissions are pre-configured** - Camera and Photo Library access already set up in project

## ❓ FAQ

### Do I need to configure Info.plist permissions?

**No!** Camera and Photo Library permissions are already configured in the project's build settings (`project.pbxproj`). When you build, Xcode automatically generates the complete Info.plist with all permissions. See [REPOSITORY_STRUCTURE.md](REPOSITORY_STRUCTURE.md) for details.

### Why is Info.plist empty?

Modern Xcode projects (iOS 15+) use build settings for most Info.plist keys. The empty Info.plist is normal and intentional. All permissions and settings are in `INFOPLIST_KEY_*` entries in the project file.

---

**Need help?** Check the troubleshooting section or ask your team members!
