import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var gitHubService: GitHubService?
    var keychainService: KeychainService?
    var notificationManager: NotificationManager?
    var workflowViewModel: WorkflowViewModel?
    
    private let refreshInterval: TimeInterval = 60.0 // Refresh every 60 seconds
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up the app to run as a menu bar app (LSUIElement = true would be in Info.plist)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize services
        keychainService = KeychainService()
        notificationManager = NotificationManager()
        workflowViewModel = WorkflowViewModel(gitHubService: nil)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "PipeWatch")
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusIcon(status: .unknown)
        }
        
        // Set up menu
        setupMenu()
        
        // Request notification permissions
        notificationManager?.requestAuthorization()
        
        // Load GitHub token and start monitoring
        if let token = keychainService?.getToken() {
            startMonitoring(with: token)
        } else {
            // Show setup if no token found
            showTokenSetup()
        }
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open PipeWatch", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshStatus), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit PipeWatch", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                showPopover(button)
            }
        }
    }
    
    func showPopover(_ sender: NSStatusBarButton) {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        
        let contentView = WorkflowListView(gitHubService: gitHubService)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        self.popover = popover
    }
    
    @objc func showPreferences() {
        showTokenSetup()
    }
    
    @objc func refreshStatus() {
        gitHubService?.fetchWorkflowRuns()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func showTokenSetup() {
        let alert = NSAlert()
        alert.messageText = "GitHub Token Required"
        alert.informativeText = "Please enter your GitHub Personal Access Token to monitor workflows."
        alert.alertStyle = .informational
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "ghp_xxxxxxxxxxxx"
        alert.accessoryView = textField
        
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let token = textField.stringValue
            if !token.isEmpty {
                keychainService?.saveToken(token)
                startMonitoring(with: token)
            }
        }
    }
    
    func startMonitoring(with token: String) {
        gitHubService = GitHubService(token: token)
        gitHubService?.delegate = self
        workflowViewModel?.gitHubService = gitHubService
        gitHubService?.fetchWorkflowRuns()
        
        // Set up periodic refresh
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.gitHubService?.fetchWorkflowRuns()
        }
    }
    
    func updateStatusIcon(status: WorkflowStatus) {
        guard let button = statusItem?.button else { return }
        
        let imageName: String
        let color: NSColor
        
        switch status {
        case .success:
            imageName = "checkmark.circle.fill"
            color = .systemGreen
        case .failure:
            imageName = "xmark.circle.fill"
            color = .systemRed
        case .inProgress:
            imageName = "clock.fill"
            color = .systemYellow
        case .unknown:
            imageName = "circle.fill"
            color = .systemGray
        }
        
        if let image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Build Status") {
            let coloredImage = image.withSymbolConfiguration(.init(pointSize: 18, weight: .regular))
            button.image = coloredImage
            button.contentTintColor = color
        }
    }
}

extension AppDelegate: GitHubServiceDelegate {
    func didUpdateWorkflows(_ workflows: [WorkflowRun]) {
        // Update the view model
        DispatchQueue.main.async { [weak self] in
            self?.workflowViewModel?.updateWorkflows(workflows)
        }
        
        // Determine overall status
        let overallStatus = calculateOverallStatus(workflows)
        updateStatusIcon(status: overallStatus)
        
        // Check for failures and recoveries, send notifications
        notificationManager?.checkForFailuresAndNotify(workflows: workflows)
    }
    
    func didFailWithError(_ error: Error) {
        print("Error fetching workflows: \(error.localizedDescription)")
        updateStatusIcon(status: .unknown)
    }
    
    private func calculateOverallStatus(_ workflows: [WorkflowRun]) -> WorkflowStatus {
        guard !workflows.isEmpty else { return .unknown }
        
        if workflows.contains(where: { $0.status == .failure }) {
            return .failure
        } else if workflows.contains(where: { $0.status == .inProgress }) {
            return .inProgress
        } else {
            return .success
        }
    }
}
