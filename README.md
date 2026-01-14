<p align="center">
  <img src="PipeWatch/docs/icon.svg" width="128" height="128" alt="PipeWatch Icon">
</p>

<h1 align="center">PipeWatch</h1>

<p align="center">
  <strong>Monitor your CI/CD pipelines from your macOS menu bar</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#building">Building</a> •
  <a href="#license">License</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-007AFF?style=flat-square&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://github.com/NeuralChowder/macosx-pipewatch/actions/workflows/release.yml/badge.svg" alt="Build Status">
</p>

---

## Features

🎯 **Menu Bar Integration** — Always accessible from your macOS status bar

🚦 **Real-time Status** — Icon color indicates overall health (green/yellow/red/gray)

📊 **Smart Filtering** — Shows only the latest run per workflow

🔔 **Desktop Notifications** — Get notified when pipelines fail or recover

🔗 **Quick Actions** — Open runs in browser directly from dropdown

🏢 **Multi-Organization** — Monitor personal and organization pipelines

🔒 **Secure** — Tokens stored in macOS Keychain

� **Launch at Login** — Optionally start PipeWatch when you log in

🛡️ **Single Instance** — Prevents duplicate app instances from running

�🔌 **Extensible** — Architecture ready for GitLab/Bitbucket support

---

## Installation

### Requirements

- macOS 14.0 (Sonoma) or later
- GitHub Personal Access Token with `repo`, `read:org`, and `workflow` scopes

### Download

Download the latest release from the [Releases](https://github.com/NeuralChowder/macosx-pipewatch/releases) page.

### Build from Source

```bash
git clone https://github.com/NeuralChowder/macosx-pipewatch.git
cd macosx-pipewatch/PipeWatch
swift build -c release
```

The binary will be at `.build/release/Pipe Watch`

---

## Usage

1. Launch PipeWatch — it appears in your menu bar
2. Click the PipeWatch icon and select **Connect Account**
3. Enter your GitHub Personal Access Token
4. Select which organizations to monitor

### Creating a GitHub Token

1. Go to **GitHub Settings** → **Developer Settings** → **Personal Access Tokens**
2. Click **Generate new token (classic)**
3. Select scopes: `repo`, `read:org`, `workflow`
4. Copy and save the token

---

## Building

### Development

```bash
cd PipeWatch
swift build           # Debug build
swift run             # Run directly
```

### Release

```bash
cd PipeWatch
swift build -c release
```

### Create App Bundle

```bash
cd PipeWatch
./build.sh
```

This creates a `Pipe Watch.app` bundle ready for distribution.

---

## Project Structure

```
macosx-pipewatch/
├── README.md
├── .gitignore
└── PipeWatch/
    ├── Package.swift
    ├── build.sh
    ├── Sources/
    │   ├── App/              # App entry point & state
    │   ├── Core/             # Providers, services, repositories
    │   └── Features/         # UI views (MenuBar, Settings, etc.)
    └── docs/
```

---

## License

MIT License — see [LICENSE](PipeWatch/LICENSE) for details.

---

<p align="center">Made with ❤️ for developers who care about their pipelines</p>
