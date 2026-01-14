# PipeWatch 🔍

A lightweight macOS menu bar app for real-time monitoring of GitHub Actions pipelines.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features ✨

- **Color-Coded Status Icon**: Instantly see build health at a glance
  - 🟢 Green: All workflows passing
  - 🟡 Yellow: Workflows in progress
  - 🔴 Red: One or more workflows failing
  - ⚪ Gray: Unknown status or no data

- **Latest Run Per Workflow**: Clean, focused view showing only the most recent run for each workflow

- **Desktop Notifications**: Get alerted about:
  - ❌ Build failures
  - ✅ Build recoveries

- **One-Click Browser Access**: Click any workflow to open it directly in your browser

- **Repository Support**: Monitor multiple repositories
  - Personal repositories
  - Organization repositories

- **Secure Token Storage**: GitHub tokens stored safely in macOS Keychain

- **Native macOS Design**: Non-intrusive menu bar integration

## Installation 📦

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)
- GitHub Personal Access Token with `repo` and `workflow` scopes

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/NeuralChowder/macosx-pipewatch.git
   cd macosx-pipewatch
   ```

2. Open in Xcode:
   ```bash
   open Package.swift
   ```

3. Build and run:
   - Select the PipeWatch scheme
   - Press `Cmd + R` to build and run

## Setup 🔧

### Creating a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "PipeWatch")
4. Select the following scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
5. Click "Generate token"
6. **Important**: Copy the token immediately (you won't be able to see it again)

### First Launch

1. Launch PipeWatch - you'll see a gray icon in your menu bar
2. Click the icon or wait for the token setup dialog
3. Paste your GitHub Personal Access Token
4. Click "Save"

The app will automatically:
- Fetch your repositories
- Monitor the most recent workflow runs
- Update every 60 seconds

## Usage 💡

### Menu Bar Icon

The menu bar icon color indicates overall build status:
- Click the icon to open the workflow list
- Right-click for quick actions menu

### Workflow List

- View all monitored workflows with their current status
- Click any workflow to open it in your browser
- See branch name, event type, and last update time

### Menu Options

- **Open PipeWatch**: Show/hide the workflow list
- **Preferences**: Update your GitHub token
- **Refresh**: Manually refresh workflow status
- **Quit**: Exit PipeWatch

### Notifications

PipeWatch sends desktop notifications for:
- **Failures**: When a workflow fails
- **Recoveries**: When a previously failing workflow succeeds

Click a notification to open the workflow run in your browser.

## Configuration ⚙️

### Adding/Removing Repositories

By default, PipeWatch monitors your 10 most recently updated repositories. The app automatically discovers repositories you have access to.

### Changing Update Frequency

The default update interval is 60 seconds. To change this, you'll need to modify the `main.swift` file:

```swift
Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
    self?.gitHubService?.fetchWorkflowRuns()
}
```

## Architecture 🏗️

```
PipeWatch/
├── Sources/
│   ├── main.swift              # App entry point and menu bar setup
│   ├── Models/
│   │   └── WorkflowRun.swift   # Data models
│   ├── Services/
│   │   ├── GitHubService.swift # GitHub API integration
│   │   ├── KeychainService.swift # Secure token storage
│   │   └── NotificationManager.swift # Desktop notifications
│   └── Views/
│       └── WorkflowListView.swift # SwiftUI interface
├── Info.plist
└── Package.swift
```

## Security 🔒

- GitHub tokens are stored securely in macOS Keychain
- No tokens or credentials are sent anywhere except to GitHub's API
- All API requests use HTTPS
- The app runs locally with no external dependencies

## Troubleshooting 🔧

### Token Not Working

1. Verify your token has the correct scopes (`repo` and `workflow`)
2. Check that the token hasn't expired
3. Try regenerating a new token

### No Workflows Showing

1. Ensure your repositories have GitHub Actions enabled
2. Check that workflows have been run at least once
3. Verify you have access to the repositories

### Notifications Not Appearing

1. Check System Preferences → Notifications → PipeWatch
2. Ensure notifications are enabled
3. Try restarting the app

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments 🙏

- Built with Swift and SwiftUI
- Uses GitHub Actions API
- Inspired by the need for better CI/CD monitoring on macOS
