# Contributing to PipeWatch

Thank you for your interest in contributing to PipeWatch! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- GitHub Personal Access Token

### Building the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/NeuralChowder/macosx-pipewatch.git
   cd macosx-pipewatch
   ```

2. Open in Xcode:
   ```bash
   open Package.swift
   ```
   
   Or use the Makefile:
   ```bash
   make xcode
   ```

3. Build the project:
   ```bash
   swift build
   # or
   make build
   ```

4. Run tests:
   ```bash
   swift test
   # or
   make test
   ```

## Code Structure

```
PipeWatch/
├── Sources/
│   ├── main.swift              # Application entry point
│   ├── Models/                 # Data models
│   │   └── WorkflowRun.swift
│   ├── Services/               # Business logic
│   │   ├── GitHubService.swift
│   │   ├── KeychainService.swift
│   │   └── NotificationManager.swift
│   └── Views/                  # UI components
│       └── WorkflowListView.swift
└── Tests/                      # Unit tests
    └── WorkflowRunTests.swift
```

## Coding Guidelines

### Swift Style

- Follow Swift API Design Guidelines
- Use 4 spaces for indentation
- Keep lines under 120 characters when possible
- Use meaningful variable and function names
- Add comments for complex logic

### Commits

- Write clear, concise commit messages
- Use present tense ("Add feature" not "Added feature")
- Reference issues and PRs when applicable

### Testing

- Add tests for new features
- Ensure all tests pass before submitting PR
- Aim for good code coverage

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`swift test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Reporting Bugs

When reporting bugs, please include:

- macOS version
- PipeWatch version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots (if applicable)

## Feature Requests

We welcome feature requests! Please:

- Check if the feature has already been requested
- Clearly describe the feature and its benefits
- Provide examples of how it would work

## Questions?

Feel free to open an issue for any questions about contributing.

## License

By contributing to PipeWatch, you agree that your contributions will be licensed under the MIT License.
