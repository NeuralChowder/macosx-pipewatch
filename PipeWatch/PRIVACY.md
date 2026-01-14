# Privacy Policy for PipeWatch

**Last Updated: January 2026**

## Overview

PipeWatch is designed with privacy as a core principle. We do not collect, store, or transmit any personal data.

## Data Collection

**We do not collect any data.**

PipeWatch operates entirely on your local machine. No information is sent to us or any third party (except the API calls to your configured CI/CD providers like GitHub).

## Data Storage

All data is stored locally on your device:

- **Settings**: Stored in `~/Library/Application Support/PipeWatch/`
- **Authentication Tokens**: Stored securely in macOS Keychain
- **Pipeline Data**: Cached in memory only, not persisted

## Third-Party Services

PipeWatch communicates directly with:

- **GitHub API** (api.github.com) - To fetch your pipeline data

These communications use your personal access token and are made directly from your device. We do not proxy or intercept these requests.

## What We Don't Do

- ❌ No analytics or telemetry
- ❌ No crash reporting services
- ❌ No user tracking
- ❌ No data sharing
- ❌ No advertising
- ❌ No cloud storage of your data

## Open Source

PipeWatch is open source. You can audit the code yourself at:
https://github.com/yourusername/pipewatch

## Contact

If you have questions about this privacy policy, please open an issue on GitHub.

## Changes

We may update this policy from time to time. Changes will be posted to this page and the GitHub repository.
