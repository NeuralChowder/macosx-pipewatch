import SwiftUI
import AppKit

// Notification for closing the popover
extension Notification.Name {
    static let closePopover = Notification.Name("closePopover")
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

// MARK: - App Delegate with NSStatusBar
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    let appState = AppState()
    let pipelineMonitor = PipelineMonitor()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        
        // Observe close popover notification
        NotificationCenter.default.addObserver(
            forName: .closePopover,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.popover.performClose(nil)
        }
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
    
    private var mainWindow: NSWindow?
    
    func openMainWindow() {
        // Close the popover first
        popover.performClose(nil)
        
        if let window = mainWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window with SwiftUI content
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
        window.makeKeyAndOrderFront(nil)
        
        // Switch to regular app temporarily to show in dock while window is open
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Track window close to switch back to accessory mode
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.mainWindow = nil
            // Go back to menu bar only mode
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.setActivationPolicy(.accessory)
            }
        }
        
        mainWindow = window
    }
    
    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
