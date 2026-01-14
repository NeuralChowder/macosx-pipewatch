import SwiftUI

/// Individual pipeline run row in the menu bar
struct PipelineRowView: View {
    let run: PipelineRun
    @EnvironmentObject var pipelineMonitor: PipelineMonitor
    @EnvironmentObject var appState: AppState
    @State private var isHovering = false
    
    var body: some View {
        Button {
            pipelineMonitor.openInBrowser(run)
        } label: {
            HStack(spacing: 10) {
                // Status icon
                statusIcon
                
                // Pipeline info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(run.repository.name)
                            .font(.system(.subheadline, weight: .medium))
                            .lineLimit(1)
                        
                        Text("/")
                            .foregroundStyle(.tertiary)
                        
                        Text(run.branch)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text(run.displayTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Time and actions
                VStack(alignment: .trailing, spacing: 2) {
                    Text(run.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    if isHovering {
                        quickActions
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - Status Icon
    
    private var statusIcon: some View {
        Group {
            if run.isRunning {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(.yellow)
            } else if let conclusion = run.conclusion {
                Image(systemName: conclusion.icon)
                    .foregroundStyle(conclusionColor(conclusion))
            } else {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 16))
        .frame(width: 24)
    }
    
    private func conclusionColor(_ conclusion: PipelineConclusion) -> Color {
        switch conclusion {
        case .success: return .green
        case .failure, .timedOut: return .red
        case .cancelled, .stale, .skipped, .neutral: return .gray
        case .actionRequired: return .yellow
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 4) {
            Button {
                pipelineMonitor.openInBrowser(run)
            } label: {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Open in browser")
            
            if run.isRunning {
                Button {
                    Task {
                        try? await pipelineMonitor.cancelRun(run, appState: appState)
                    }
                } label: {
                    Image(systemName: "stop.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Cancel run")
            } else {
                Button {
                    Task {
                        try? await pipelineMonitor.rerunPipeline(run, appState: appState)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Rerun pipeline")
            }
        }
    }
}
