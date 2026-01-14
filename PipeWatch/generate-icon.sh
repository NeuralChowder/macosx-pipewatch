#!/bin/bash

# Generate macOS app icon from SVG
# Requires: Inkscape or rsvg-convert (from librsvg)

set -e

SVG_FILE="docs/icon.svg"
ICONSET_DIR="AppIcon.iconset"
OUTPUT_ICNS="Sources/Resources/AppIcon.icns"

# Check if SVG exists
if [ ! -f "$SVG_FILE" ]; then
    echo "❌ SVG file not found: $SVG_FILE"
    exit 1
fi

# Create iconset directory
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

echo "🎨 Generating icon sizes from SVG..."

# Required sizes for macOS app icons
sizes=(16 32 64 128 256 512 1024)

# Try to use rsvg-convert first (more common), fall back to sips
if command -v rsvg-convert &> /dev/null; then
    echo "Using rsvg-convert..."
    for size in "${sizes[@]}"; do
        rsvg-convert -w $size -h $size "$SVG_FILE" -o "$ICONSET_DIR/icon_${size}x${size}.png"
        if [ $size -le 512 ]; then
            # Create @2x versions
            double=$((size * 2))
            rsvg-convert -w $double -h $double "$SVG_FILE" -o "$ICONSET_DIR/icon_${size}x${size}@2x.png"
        fi
    done
elif command -v inkscape &> /dev/null; then
    echo "Using Inkscape..."
    for size in "${sizes[@]}"; do
        inkscape -w $size -h $size "$SVG_FILE" -o "$ICONSET_DIR/icon_${size}x${size}.png" 2>/dev/null
        if [ $size -le 512 ]; then
            double=$((size * 2))
            inkscape -w $double -h $double "$SVG_FILE" -o "$ICONSET_DIR/icon_${size}x${size}@2x.png" 2>/dev/null
        fi
    done
else
    echo "❌ Neither rsvg-convert nor Inkscape found."
    echo "Install with: brew install librsvg"
    echo "         or: brew install inkscape"
    exit 1
fi

# Rename to Apple's expected naming convention
mv "$ICONSET_DIR/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png" 2>/dev/null || true
mv "$ICONSET_DIR/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png" 2>/dev/null || true
mv "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null || true
mv "$ICONSET_DIR/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png" 2>/dev/null || true
mv "$ICONSET_DIR/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png" 2>/dev/null || true
mv "$ICONSET_DIR/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png" 2>/dev/null || true
mv "$ICONSET_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null || true

# Clean up any extra files
rm -f "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_1024x1024.png" 2>/dev/null || true

echo "📦 Creating .icns file..."

# Create the icns file
mkdir -p "$(dirname "$OUTPUT_ICNS")"
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

# Clean up
rm -rf "$ICONSET_DIR"

echo "✅ Icon created: $OUTPUT_ICNS"
