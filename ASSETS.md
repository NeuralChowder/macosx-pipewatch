# PipeWatch Assets

## App Icons

PipeWatch uses SF Symbols for all icons:

- **Menu Bar Icon**: Circle filled icon that changes color based on status
  - Green (`checkmark.circle.fill`): All workflows passing
  - Red (`xmark.circle.fill`): One or more workflows failing
  - Yellow (`clock.fill`): Workflows in progress
  - Gray (`circle.fill`): Unknown/No data

- **Workflow Status Icons**:
  - Success: `checkmark.circle.fill` (green)
  - Failure: `xmark.circle.fill` (red)
  - In Progress: `clock.fill` (orange/yellow)
  - Unknown: `questionmark.circle.fill` (gray)

- **UI Icons**:
  - Refresh: `arrow.clockwise`
  - Branch: `arrow.branch`
  - External Link: `arrow.up.forward.square`
  - Empty State: `tray`

## Color Scheme

The app uses native macOS colors for proper dark/light mode support:

- **Status Colors**:
  - Success: `NSColor.systemGreen`
  - Failure: `NSColor.systemRed`
  - In Progress: `NSColor.systemYellow`
  - Unknown: `NSColor.systemGray`

- **UI Colors**:
  - Background: `NSColor.controlBackgroundColor`
  - Secondary Text: `Color.secondary`
  - Separators: `NSColor.separatorColor`

## Notifications

Notifications use emoji for visual clarity:
- Failure: ❌
- Recovery: ✅

## Screenshots

To add screenshots:
1. Run PipeWatch
2. Take screenshots of key features
3. Add to README under Features section

Key screenshots to capture:
- Menu bar icon in different states
- Workflow list popover
- Notification examples
- Token setup dialog
