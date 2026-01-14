import SwiftUI

class WorkflowViewModel: ObservableObject {
    @Published var workflows: [WorkflowRun] = []
    var gitHubService: GitHubService?
    
    init(gitHubService: GitHubService?) {
        self.gitHubService = gitHubService
    }
    
    func refresh() {
        gitHubService?.fetchWorkflowRuns()
    }
    
    func updateWorkflows(_ workflows: [WorkflowRun]) {
        self.workflows = workflows
    }
}

struct WorkflowListView: View {
    @StateObject private var viewModel: WorkflowViewModel
    
    init(gitHubService: GitHubService?) {
        _viewModel = StateObject(wrappedValue: WorkflowViewModel(gitHubService: gitHubService))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PipeWatch")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Workflow list
            if viewModel.workflows.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No workflows found")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("Add repositories in preferences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.workflows) { workflow in
                            WorkflowRowView(workflow: workflow)
                                .onTapGesture {
                                    openInBrowser(workflow.htmlURL)
                                }
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
    
    private func openInBrowser(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct WorkflowRowView: View {
    let workflow: WorkflowRun
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status icon
            statusIcon
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workflow.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Label(workflow.headBranch, systemImage: "arrow.branch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(workflow.event)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(timeAgo(from: workflow.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.forward.square")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch workflow.status {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .inProgress:
            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
        case .unknown:
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.gray)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    WorkflowListView(gitHubService: nil)
}
