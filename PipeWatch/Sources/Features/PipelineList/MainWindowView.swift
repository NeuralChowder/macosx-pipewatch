import SwiftUI

/// Main application window showing all pipelines
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipelineMonitor: PipelineMonitor
    @State private var searchText = ""
    @State private var selectedFilter: PipelineFilter = .all
    @State private var selectedRun: PipelineRun?
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            toolbarContent
        }
        .searchable(text: $searchText, prompt: "Search pipelines...")
        .onAppear {
            pipelineMonitor.startMonitoring(appState: appState)
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selectedRun) {
            ForEach(filteredRuns) { run in
                PipelineListRowView(run: run)
                    .tag(run)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Pipelines")
        .safeAreaInset(edge: .top) {
            filterPicker
        }
    }
    
    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(PipelineFilter.allCases, id: \.self) { filter in
                Label(filter.displayName, systemImage: filter.icon)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Detail View
    
    @ViewBuilder
    private var detailView: some View {
        if let run = selectedRun {
            PipelineDetailView(run: run)
        } else {
            emptySelection
        }
    }
    
    private var emptySelection: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Select a Pipeline")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Choose a pipeline from the sidebar to view details")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task {
                    await pipelineMonitor.refresh(appState: appState)
                }
            } label: {
                if pipelineMonitor.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .help("Refresh pipelines")
            .keyboardShortcut("r", modifiers: .command)
        }
        
        ToolbarItem(placement: .status) {
            StatusIndicator(status: pipelineMonitor.aggregateStatus)
        }
        
        ToolbarItem(placement: .navigation) {
            if let lastRefresh = pipelineMonitor.lastRefresh {
                Text("Updated \(lastRefresh.timeAgoDisplay())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Filtering
    
    private var filteredRuns: [PipelineRun] {
        var runs = pipelineMonitor.runs
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .failed:
            runs = runs.filter { $0.isFailed }
        case .running:
            runs = runs.filter { $0.isRunning }
        case .successful:
            runs = runs.filter { $0.isSuccessful }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            runs = runs.filter { run in
                run.repository.name.localizedCaseInsensitiveContains(searchText) ||
                run.branch.localizedCaseInsensitiveContains(searchText) ||
                run.commitMessage.localizedCaseInsensitiveContains(searchText) ||
                run.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return runs
    }
}

// MARK: - Filter Enum

enum PipelineFilter: String, CaseIterable {
    case all
    case failed
    case running
    case successful
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .failed: return "Failed"
        case .running: return "Running"
        case .successful: return "Successful"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .failed: return "xmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        case .successful: return "checkmark.circle.fill"
        }
    }
}

// MARK: - List Row View

struct PipelineListRowView: View {
    let run: PipelineRun
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(run.repository.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(run.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(systemName: "arrow.branch")
                        .font(.caption2)
                    Text(run.branch)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(run.displayTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: some View {
        Group {
            if run.isRunning {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(.yellow)
            } else if run.isFailed {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            } else if run.isSuccessful {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.gray)
            }
        }
        .font(.title2)
    }
}
