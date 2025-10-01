#!/bin/bash
#
# Developer Setup Script for swift-cam
# This script helps set up developer-specific signing configuration
#

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/swift-cam/DeveloperSettings.xcconfig"
EXAMPLE_FILE="$SCRIPT_DIR/swift-cam/DeveloperSettings.xcconfig.example.xcconfig"

echo "🚀 Swift-Cam Developer Setup"
echo "============================"
echo ""

# Check if config file already exists
if [ -f "$CONFIG_FILE" ]; then
    echo "✓ DeveloperSettings.xcconfig already exists"
    echo ""
    read -p "Do you want to reconfigure it? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Setup complete - using existing configuration"
        exit 0
    fi
fi

# Check if example file exists
if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "❌ Error: Example config file not found at:"
    echo "   $EXAMPLE_FILE"
    exit 1
fi

echo "📝 Please provide your developer information:"
echo ""

# Get Team ID
echo "1️⃣  Apple Developer Team ID"
echo "   (Find this at: https://developer.apple.com/account/#/membership)"
read -p "   Enter your Team ID: " TEAM_ID

# Get Bundle Identifier
echo ""
echo "2️⃣  Bundle Identifier"
echo "   (e.g., com.yourname.swift-cam)"
read -p "   Enter your Bundle ID: " BUNDLE_ID

# Validate inputs
if [ -z "$TEAM_ID" ] || [ -z "$BUNDLE_ID" ]; then
    echo ""
    echo "❌ Error: Team ID and Bundle ID cannot be empty"
    exit 1
fi

# Create config file
echo ""
echo "📄 Creating DeveloperSettings.xcconfig..."

cat > "$CONFIG_FILE" << EOF
//
//  DeveloperSettings.xcconfig
//  swift-cam
//
//  Developer: $(whoami)
//  Generated: $(date)
//

// Configuration settings file format documentation can be found at:
// https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project

// Team & Signing
DEVELOPMENT_TEAM = $TEAM_ID
CODE_SIGN_STYLE = Automatic

// Bundle Identifier
PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID
EOF

echo "✅ Configuration file created successfully!"
echo ""
echo "📋 Your configuration:"
echo "   Team ID: $TEAM_ID"
echo "   Bundle ID: $BUNDLE_ID"
echo ""
echo "🎉 Setup complete! You can now:"
echo "   1. Open the project in Xcode"
echo "   2. Build and run without signing conflicts"
echo "   3. Commit and push changes (your config won't be committed)"
echo ""
echo "ℹ️  Note: This file is git-ignored and won't be shared with others"
