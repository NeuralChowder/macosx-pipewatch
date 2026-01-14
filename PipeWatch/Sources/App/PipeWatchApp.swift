import SwiftUI
import AppKit

// Notification for closing the popover
extension Notification.Name {
    static let closePopover = Notification.Name("closePopover")
    static let openMainWindow = Notification.Name("openMainWindow")
}

@main
struct PipeWatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Settings window only - main window is managed by AppDelegate
        Settings {
            SettingsView()
                .environmentObject(appDelegate.appState)
                .environmentObject(appDelegate.pipelineMonitor)
        }
    }
}

// MARK: - Main Window Controller
@MainActor
class MainWindowController: NSWindowController, NSWindowDelegate {
    var onWindowClosed: (() -> Void)?
    
    init(appState: AppState, pipelineMonitor: PipelineMonitor) {
        let contentView = MainWindowView()
            .environmentObject(appState)
            .environmentObject(pipelineMonitor)
            .frame(minWidth: 800, minHeight: 600)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pipe Watch"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    nonisolated func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.onWindowClosed?()
        }
    }
}

// MARK: - App Delegate with NSStatusBar
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    let appState = AppState()
    let pipelineMonitor = PipelineMonitor()
    
    private var mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for existing instance and quit if already running
        if !ensureSingleInstance() {
            NSApp.terminate(nil)
            return
        }
        
        // Hide from dock - menu bar only
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use a template image for proper menu bar appearance
            let image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: "Pipeline Status")
            image?.isTemplate = true // This ensures proper contrast in menu bar
            button.image = image
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover with SwiftUI view
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 450)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(appState)
                .environmentObject(pipelineMonitor)
        )
        
        // Start monitoring
        pipelineMonitor.startMonitoring(appState: appState)
        
        // Observe status changes to update icon
        Task { @MainActor in
            for await _ in pipelineMonitor.$aggregateStatus.values {
                updateStatusIcon()
            }
        }
        
        print("✅ Pipe Watch is running!")
        print("📍 Look for the icon in your menu bar (top right of screen)")
        
        // Set up notification observers
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Observe close popover notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClosePopover),
            name: .closePopover,
            object: nil
        )
        
        // Observe open main window notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenMainWindow),
            name: .openMainWindow,
            object: nil
        )
    }
    
    @objc private func handleClosePopover() {
        popover?.performClose(nil)
    }
    
    @objc private func handleOpenMainWindow() {
        openMainWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up observers before termination
        NotificationCenter.default.removeObserver(self)
        mainWindowController = nil
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Ensure popover gets focus
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        
        let symbolName: String
        
        switch pipelineMonitor.aggregateStatus {
        case .allPassing:
            symbolName = "checkmark.circle.fill"
        case .someRunning:
            symbolName = "arrow.triangle.2.circlepath.circle.fill"
        case .someFailing:
            symbolName = "exclamationmark.circle.fill"
        case .noData:
            symbolName = "circle.dashed"
        case .error:
            symbolName = "exclamationmark.triangle.fill"
        }
        
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Pipeline Status") {
            image.isTemplate = true // Template images automatically adapt to menu bar
            button.image = image
        }
    }
    
    // MARK: - Main Window Management
    
    func openMainWindow() {
        // Close the popover first
        popover?.performClose(nil)
        
        if let controller = mainWindowController, controller.window?.isVisible == true {
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window controller
        let controller = MainWindowController(appState: appState, pipelineMonitor: pipelineMonitor)
        controller.onWindowClosed = { [weak self] in
            self?.mainWindowController = nil
            // Go back to menu bar only mode
            NSApp.setActivationPolicy(.accessory)
        }
        controller.showWindow(nil)
        
        // Switch to regular app temporarily to show in dock while window is open
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        mainWindowController = controller
    }
    
    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // MARK: - Single Instance Check
    
    private func ensureSingleInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.pipewatch.app"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        
        // If more than one instance (including self), we're a duplicate
        if runningApps.count > 1 {
            // Activate the existing instance
            if let existingApp = runningApps.first(where: { $0 != NSRunningApplication.current }) {
                existingApp.activate()
            }
            return false
        }
        return true
    }
}
