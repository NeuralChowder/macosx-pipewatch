import SwiftUI

/// Status bar icon view that changes based on pipeline status
struct StatusBarIconView: View {
    let status: AggregateStatus
    
    var body: some View {
        Image(systemName: status.icon)
            .symbolRenderingMode(.palette)
            .foregroundStyle(iconColor, .secondary)
    }
    
    private var iconColor: Color {
        switch status {
        case .allPassing:
            return .green
        case .someRunning:
            return .yellow
        case .someFailing:
            return .red
        case .noData:
            return .gray
        case .error:
            return .orange
        }
    }
}

/// Menu bar dropdown view
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipelineMonitor: PipelineMonitor
    @State private var showingSettings = false
    @State private var showingAddAccount = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
                .padding(.vertical, 4)
            
            if !appState.isAuthenticated {
                notAuthenticatedView
            } else if pipelineMonitor.runs.isEmpty && !pipelineMonitor.isLoading {
                emptyStateView
            } else {
                pipelinesList
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Footer actions
            footerSection
        }
        .frame(width: 360)
        .padding(.vertical, 8)
        .onAppear {
            pipelineMonitor.startMonitoring(appState: appState)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Git Pipeline Monitor")
                    .font(.headline)
                
                if let lastRefresh = pipelineMonitor.lastRefresh {
                    Text("Updated \(lastRefresh.timeAgoDisplay())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if pipelineMonitor.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                StatusIndicator(status: pipelineMonitor.aggregateStatus)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
    
    // MARK: - Pipeline List
    
    private var pipelinesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Failed runs first
                if !pipelineMonitor.failedRuns().isEmpty {
                    sectionHeader("Failed")
                    ForEach(pipelineMonitor.failedRuns().prefix(5)) { run in
                        PipelineRowView(run: run)
                    }
                }
                
                // Running runs
                if !pipelineMonitor.runningRuns().isEmpty {
                    sectionHeader("Running")
                    ForEach(pipelineMonitor.runningRuns().prefix(5)) { run in
                        PipelineRowView(run: run)
                    }
                }
                
                // Successful runs (latest only)
                let successfulRuns = pipelineMonitor.successfulRuns()
                if !successfulRuns.isEmpty {
                    sectionHeader("Successful")
                    ForEach(successfulRuns.prefix(5)) { run in
                        PipelineRowView(run: run)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Empty States
    
    private var notAuthenticatedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("Not Connected")
                .font(.headline)
            
            Text("Connect your GitHub account to monitor pipelines")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Connect Account") {
                showingAddAccount = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .sheet(isPresented: $showingAddAccount) {
            AddAccountView()
                .environmentObject(appState)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No Recent Pipelines")
                .font(.headline)
            
            Text("No pipeline runs found in the last \(appState.filterDays) days")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh") {
                Task {
                    await pipelineMonitor.refresh(appState: appState)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 4) {
            HStack {
                Button {
                    Task {
                        await pipelineMonitor.refresh(appState: appState)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(pipelineMonitor.isLoading)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(",", modifiers: .command)
                
                Spacer()
                
                Button {
                    // Get AppDelegate and open main window
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.openMainWindow()
                    }
                } label: {
                    Label("View All", systemImage: "list.bullet")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, 12)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(pipelineMonitor)
                .frame(width: 500, height: 400)
        }
    }
}

/// Status indicator badge
struct StatusIndicator: View {
    let status: AggregateStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .allPassing: return .green
        case .someRunning: return .yellow
        case .someFailing: return .red
        case .noData: return .gray
        case .error: return .orange
        }
    }
    
    private var statusText: String {
        switch status {
        case .allPassing: return "All Passing"
        case .someRunning: return "Running"
        case .someFailing: return "Failing"
        case .noData: return "No Data"
        case .error: return "Error"
        }
    }
}
