#!/bin/bash

# Pipe Watch Build Script
# Creates a distributable .app bundle

set -e

APP_NAME="Pipe Watch"
BUNDLE_ID="com.pipewatch.app"
VERSION="1.0.0"

echo "🔨 Building $APP_NAME v$VERSION..."

# Build release
swift build -c release

# Create app bundle structure
echo "📦 Creating app bundle..."
rm -rf "$APP_NAME.app"
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy executable
cp ".build/release/$APP_NAME" "$APP_NAME.app/Contents/MacOS/"

# Copy Info.plist
cp "Sources/Resources/Info.plist" "$APP_NAME.app/Contents/"

# Create PkgInfo
echo -n "APPL????" > "$APP_NAME.app/Contents/PkgInfo"

echo "✅ App bundle created: $APP_NAME.app"
echo ""
echo "To sign the app for distribution:"
echo "  codesign --force --deep --sign \"Developer ID Application: Your Name\" $APP_NAME.app"
echo ""
echo "To notarize for distribution outside App Store:"
echo "  xcrun notarytool submit $APP_NAME.app --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID"
echo ""
echo "To create a DMG:"
echo "  hdiutil create -volname \"$APP_NAME\" -srcfolder \"$APP_NAME.app\" -ov \"$APP_NAME-$VERSION.dmg\""
