# PipeWatch Icon Design Brief

## Concept
A visual representation of monitoring CI/CD pipelines - combining the ideas of "pipe" and "watch/monitor".

## Suggested Designs

### Option 1: Pipeline with Eye
- A horizontal pipe/tube segment
- An eye symbol integrated, suggesting "watching"
- Green/blue gradient

### Option 2: Checkmark in Circle (Pipeline Flow)
- Circular flow arrows (like a pipeline cycle)
- Checkmark in center when passing
- Could animate to show running state

### Option 3: P Letter with Pipe
- Stylized "P" made from pipe segments
- Status indicator (dot/glow) that can be green/yellow/red
- Modern, minimal design

## Color Palette
- Primary: #007AFF (Apple Blue) or #34C759 (Apple Green)  
- Secondary: #5856D6 (Purple) for accents
- Background: Gradient or solid
- Status colors: Green (#34C759), Yellow (#FFCC00), Red (#FF3B30)

## Requirements for App Store

### macOS App Icon Sizes
- 16x16 (16pt @1x)
- 32x32 (16pt @2x, 32pt @1x)
- 64x64 (32pt @2x)
- 128x128 (128pt @1x)
- 256x256 (128pt @2x, 256pt @1x)
- 512x512 (256pt @2x, 512pt @1x)
- 1024x1024 (512pt @2x, App Store)

### File Format
- PNG format
- No transparency for App Store (1024x1024)
- sRGB color space

### Guidelines
- Should look good at small sizes (16x16)
- Works on both light and dark backgrounds
- No text in the icon
- Simple, recognizable silhouette
- Follows Apple Human Interface Guidelines

## Menu Bar Icon
- Separate from app icon
- Template image (single color, adapts to light/dark mode)
- 18x18 or 22x22 points
- Different states:
  - circle.dashed (no data)
  - checkmark.circle.fill (all passing)
  - arrow.triangle.2.circlepath.circle.fill (running)
  - exclamationmark.circle.fill (failing)

## Tools for Creation
- Figma
- Sketch
- Adobe Illustrator
- SF Symbols app (for menu bar icons)

## Export as Asset Catalog
Create `AppIcon.appiconset` folder with:
- Contents.json (manifest)
- All required PNG sizes
