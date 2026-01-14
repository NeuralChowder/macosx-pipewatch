import Foundation
import SwiftUI
import UserNotifications

/// Monitors pipelines and manages background refresh
@MainActor
class PipelineMonitor: ObservableObject {
    @Published var runs: [PipelineRun] = []
    @Published var aggregateStatus: AggregateStatus = .noData
    @Published var isLoading: Bool = false
    @Published var lastRefresh: Date?
    @Published var error: Error?
    
    private var refreshTask: Task<Void, Never>?
    private let providers: [CIProvider] = [GitHubActionsProvider()]
    private let notificationService = NotificationService()
    
    private var previousRunStatuses: [String: PipelineConclusion?] = [:]
    
    var refreshInterval: TimeInterval = 60
    var filterDays: Int = 3
    var showNotifications: Bool = true
    
    // MARK: - Monitoring Control
    
    func startMonitoring(appState: AppState) {
        stopMonitoring()
        
        refreshInterval = appState.refreshInterval
        filterDays = appState.filterDays
        showNotifications = appState.showNotifications
        
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh(appState: appState)
                try? await Task.sleep(for: .seconds(refreshInterval))
            }
        }
    }
    
    func stopMonitoring() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    // MARK: - Data Fetching
    
    func refresh(appState: AppState) async {
        guard !appState.accounts.isEmpty else {
            runs = []
            aggregateStatus = .noData
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            var allRuns: [PipelineRun] = []
            let sinceDate = Calendar.current.date(byAdding: .day, value: -filterDays, to: Date()) ?? Date()
            
            for account in appState.accounts {
                guard let provider = providers.first(where: { $0.providerType == account.provider }),
                      let token = try await KeychainService.shared.getToken(for: account.id) else {
                    continue
                }
                
                let organizations = appState.selectedOrganizations.isEmpty 
                    ? [account.username] 
                    : appState.selectedOrganizations
                
                let runs = try await provider.fetchAllPipelineRuns(
                    token: token,
                    organizations: organizations,
                    since: sinceDate
                )
                allRuns.append(contentsOf: runs)
            }
            
            // Sort by most recent
            allRuns.sort { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
            
            // Check for status changes and notify
            if showNotifications {
                checkForStatusChanges(newRuns: allRuns)
            }
            
            runs = allRuns
            aggregateStatus = computeAggregateStatus(allRuns)
            lastRefresh = Date()
            
        } catch {
            print("Pipeline refresh error: \(error)")
            self.error = error
            // Don't show error icon - just show noData if fetch fails
            // This prevents confusing error states when there are network issues
            if runs.isEmpty {
                aggregateStatus = .noData
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Actions
    
    func cancelRun(_ run: PipelineRun, appState: AppState) async throws {
        guard let account = appState.accounts.first(where: { $0.provider == run.repository.provider }),
              let provider = providers.first(where: { $0.providerType == run.repository.provider }),
              let token = try await KeychainService.shared.getToken(for: account.id) else {
            throw PipelineError.noAccount
        }
        
        try await provider.cancelPipeline(token: token, run: run)
        await refresh(appState: appState)
    }
    
    func rerunPipeline(_ run: PipelineRun, appState: AppState) async throws {
        guard let account = appState.accounts.first(where: { $0.provider == run.repository.provider }),
              let provider = providers.first(where: { $0.providerType == run.repository.provider }),
              let token = try await KeychainService.shared.getToken(for: account.id) else {
            throw PipelineError.noAccount
        }
        
        try await provider.rerunPipeline(token: token, run: run)
        await refresh(appState: appState)
    }
    
    func openInBrowser(_ run: PipelineRun) {
        NotificationCenter.default.post(name: .closePopover, object: nil)
        NSWorkspace.shared.open(run.url)
    }
    
    // MARK: - Helpers
    
    private func computeAggregateStatus(_ runs: [PipelineRun]) -> AggregateStatus {
        if runs.isEmpty {
            return .noData
        }
        
        // Get only the latest run per workflow for status computation
        let latestRuns = latestRunsPerWorkflow()
        
        let hasFailing = latestRuns.contains { $0.isFailed }
        let hasRunning = latestRuns.contains { $0.isRunning }
        
        if hasFailing {
            return .someFailing
        } else if hasRunning {
            return .someRunning
        } else {
            return .allPassing
        }
    }
    
    private func checkForStatusChanges(newRuns: [PipelineRun]) {
        for run in newRuns {
            let previousConclusion = previousRunStatuses[run.id]
            
            // Only notify if status changed to failure
            if run.conclusion == .failure && previousConclusion != .failure {
                notificationService.sendFailureNotification(for: run)
            }
            
            // Only notify if status changed from failure to success
            if run.conclusion == .success && previousConclusion == .failure {
                notificationService.sendRecoveryNotification(for: run)
            }
            
            previousRunStatuses[run.id] = run.conclusion
        }
    }
    
    // MARK: - Filtering
    
    /// Returns only the latest run for each workflow (repo + workflow combination)
    /// This is the primary data source for status display
    func latestRunsPerWorkflow() -> [PipelineRun] {
        // Group by repository + workflowId to get unique workflows
        var latestByWorkflow: [String: PipelineRun] = [:]
        
        for run in runs {
            let key = "\(run.repository.fullName)-\(run.workflowId)"
            if let existing = latestByWorkflow[key] {
                // Keep the more recent one
                if (run.startedAt ?? .distantPast) > (existing.startedAt ?? .distantPast) {
                    latestByWorkflow[key] = run
                }
            } else {
                latestByWorkflow[key] = run
            }
        }
        
        return Array(latestByWorkflow.values)
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }
    
    func runsByRepository() -> [Repository: [PipelineRun]] {
        Dictionary(grouping: latestRunsPerWorkflow(), by: { $0.repository })
    }
    
    func latestRunPerRepository() -> [PipelineRun] {
        let grouped = runsByRepository()
        return grouped.compactMap { $0.value.first }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }
    
    func failedRuns() -> [PipelineRun] {
        latestRunsPerWorkflow().filter { $0.isFailed }
    }
    
    func runningRuns() -> [PipelineRun] {
        latestRunsPerWorkflow().filter { $0.isRunning }
    }
    
    func successfulRuns() -> [PipelineRun] {
        latestRunsPerWorkflow().filter { $0.isSuccessful }
    }
}

// MARK: - Errors

enum PipelineError: LocalizedError {
    case noAccount
    case noToken
    
    var errorDescription: String? {
        switch self {
        case .noAccount:
            return "No account found for this provider"
        case .noToken:
            return "No authentication token found"
        }
    }
}
