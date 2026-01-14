import SwiftUI

/// Detailed view for a single pipeline run
struct PipelineDetailView: View {
    let run: PipelineRun
    @EnvironmentObject var pipelineMonitor: PipelineMonitor
    @EnvironmentObject var appState: AppState
    @State private var isRerunning = false
    @State private var isCancelling = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                Divider()
                
                // Status and timing
                statusSection
                
                Divider()
                
                // Commit info
                commitSection
                
                Divider()
                
                // Actions
                actionsSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                statusBadge
                Spacer()
                providerBadge
            }
            
            Text(run.name)
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Label(run.repository.fullName, systemImage: "folder")
                Text("•")
                    .foregroundStyle(.tertiary)
                Label(run.branch, systemImage: "arrow.branch")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            if run.isRunning {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                Text("Running")
            } else if let conclusion = run.conclusion {
                Image(systemName: conclusion.icon)
                Text(conclusion.displayName)
            } else {
                Image(systemName: "clock")
                Text(run.status.displayName)
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(statusColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var providerBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
            Text(run.repository.provider.rawValue)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        if run.isRunning {
            return .yellow
        } else if run.isFailed {
            return .red
        } else if run.isSuccessful {
            return .green
        } else {
            return .gray
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                if let startedAt = run.startedAt {
                    GridRow {
                        Label("Started", systemImage: "play.circle")
                            .foregroundStyle(.secondary)
                        Text(startedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                
                if let updatedAt = run.updatedAt {
                    GridRow {
                        Label("Updated", systemImage: "clock")
                            .foregroundStyle(.secondary)
                        Text(updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                
                if let startedAt = run.startedAt, let updatedAt = run.updatedAt {
                    GridRow {
                        Label("Duration", systemImage: "timer")
                            .foregroundStyle(.secondary)
                        Text(formatDuration(from: startedAt, to: updatedAt))
                    }
                }
                
                GridRow {
                    Label("Triggered by", systemImage: "person")
                        .foregroundStyle(.secondary)
                    Text(run.triggeredBy)
                }
            }
            .font(.subheadline)
        }
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
    
    // MARK: - Commit Section
    
    private var commitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Commit")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(run.displayTitle)
                    .font(.subheadline)
                
                HStack {
                    Text(String(run.commitSHA.prefix(7)))
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(run.commitSHA, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Copy full SHA")
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button {
                    pipelineMonitor.openInBrowser(run)
                } label: {
                    Label("View in Browser", systemImage: "safari")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                
                if run.isRunning {
                    Button {
                        cancelRun()
                    } label: {
                        if isCancelling {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Label("Cancel", systemImage: "stop.circle")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isCancelling)
                } else {
                    Button {
                        rerunPipeline()
                    } label: {
                        if isRerunning {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Label("Rerun", systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRerunning)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Actions
    
    private func cancelRun() {
        isCancelling = true
        Task {
            try? await pipelineMonitor.cancelRun(run, appState: appState)
            isCancelling = false
        }
    }
    
    private func rerunPipeline() {
        isRerunning = true
        Task {
            try? await pipelineMonitor.rerunPipeline(run, appState: appState)
            isRerunning = false
        }
    }
}
