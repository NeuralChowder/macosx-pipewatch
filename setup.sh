#!/bin/bash

# PipeWatch Setup Script
# This script helps set up the development environment for PipeWatch

set -e

echo "🔍 PipeWatch Setup Script"
echo "========================="
echo ""

# Check macOS version
echo "Checking macOS version..."
macos_version=$(sw_vers -productVersion)
echo "✓ Running macOS $macos_version"

# Check Xcode
echo "Checking Xcode installation..."
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi
xcode_version=$(xcodebuild -version | head -n 1)
echo "✓ $xcode_version installed"

# Check Swift
echo "Checking Swift version..."
if ! command -v swift &> /dev/null; then
    echo "❌ Swift is not available. Please ensure Xcode Command Line Tools are installed."
    exit 1
fi
swift_version=$(swift --version | head -n 1)
echo "✓ $swift_version"

# Build the project
echo ""
echo "Building PipeWatch..."
swift build -c release

if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo ""
    echo "Next steps:"
    echo "1. Open the project in Xcode: open Package.swift"
    echo "2. Run the app from Xcode"
    echo "3. You'll need a GitHub Personal Access Token"
    echo "   - Go to: https://github.com/settings/tokens"
    echo "   - Generate a token with 'repo' and 'workflow' scopes"
    echo ""
    echo "Happy monitoring! 🚀"
else
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi
