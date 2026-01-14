import Foundation

/// Protocol defining the interface for CI/CD providers
/// This abstraction allows easy addition of new providers (GitLab, Bitbucket, etc.)
protocol CIProvider {
    /// Provider name for display
    var name: String { get }
    
    /// Provider type identifier
    var providerType: ProviderType { get }
    
    /// Validate authentication token
    func validateToken(_ token: String) async throws -> ProviderAccount
    
    /// Fetch organizations/groups accessible to the authenticated user
    func fetchOrganizations(token: String) async throws -> [Organization]
    
    /// Fetch repositories for given organization(s) or user
    func fetchRepositories(token: String, organizations: [String]) async throws -> [Repository]
    
    /// Fetch pipeline/workflow runs for a repository
    func fetchPipelineRuns(token: String, repository: Repository) async throws -> [PipelineRun]
    
    /// Fetch all recent pipeline runs across all accessible repositories
    func fetchAllPipelineRuns(token: String, organizations: [String], since: Date) async throws -> [PipelineRun]
    
    /// Get the direct URL to a pipeline run
    func getPipelineURL(_ run: PipelineRun) -> URL
    
    /// Cancel a running pipeline
    func cancelPipeline(token: String, run: PipelineRun) async throws
    
    /// Rerun a pipeline
    func rerunPipeline(token: String, run: PipelineRun) async throws
}

/// Organization/Group model
struct Organization: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let login: String
    let avatarURL: URL?
    let provider: ProviderType
    let isPersonal: Bool
    
    init(id: String, name: String, login: String, avatarURL: URL? = nil, provider: ProviderType, isPersonal: Bool = false) {
        self.id = id
        self.name = name
        self.login = login
        self.avatarURL = avatarURL
        self.provider = provider
        self.isPersonal = isPersonal
    }
}

/// Repository model
struct Repository: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let fullName: String
    let owner: String
    let provider: ProviderType
    let url: URL
    let defaultBranch: String
    let isPrivate: Bool
    
    init(id: String, name: String, fullName: String, owner: String, provider: ProviderType, url: URL, defaultBranch: String = "main", isPrivate: Bool = false) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.owner = owner
        self.provider = provider
        self.url = url
        self.defaultBranch = defaultBranch
        self.isPrivate = isPrivate
    }
}

/// Pipeline/Workflow run model
struct PipelineRun: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let status: PipelineStatus
    let conclusion: PipelineConclusion?
    let branch: String
    let commitSHA: String
    let commitMessage: String
    let startedAt: Date?
    let updatedAt: Date?
    let url: URL
    let repository: Repository
    let triggeredBy: String
    let workflowId: String
    
    var displayTitle: String {
        commitMessage.components(separatedBy: "\n").first ?? commitMessage
    }
    
    var timeAgo: String {
        guard let date = startedAt ?? updatedAt else { return "Unknown" }
        return date.timeAgoDisplay()
    }
    
    var isRunning: Bool {
        status == .inProgress || status == .queued || status == .waiting || status == .pending
    }
    
    var isFailed: Bool {
        conclusion == .failure || conclusion == .timedOut || conclusion == .actionRequired
    }
    
    var isSuccessful: Bool {
        status == .completed && conclusion == .success
    }
}

/// Pipeline status
enum PipelineStatus: String, Codable, CaseIterable {
    case queued = "queued"
    case waiting = "waiting"
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case requested = "requested"
    
    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .waiting: return "Waiting"
        case .pending: return "Pending"
        case .inProgress: return "Running"
        case .completed: return "Completed"
        case .requested: return "Requested"
        }
    }
    
    var icon: String {
        switch self {
        case .queued, .waiting, .pending, .requested:
            return "clock.fill"
        case .inProgress:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}

/// Pipeline conclusion (only set when status is completed)
enum PipelineConclusion: String, Codable, CaseIterable {
    case success = "success"
    case failure = "failure"
    case cancelled = "cancelled"
    case skipped = "skipped"
    case timedOut = "timed_out"
    case actionRequired = "action_required"
    case neutral = "neutral"
    case stale = "stale"
    
    var displayName: String {
        switch self {
        case .success: return "Success"
        case .failure: return "Failed"
        case .cancelled: return "Cancelled"
        case .skipped: return "Skipped"
        case .timedOut: return "Timed Out"
        case .actionRequired: return "Action Required"
        case .neutral: return "Neutral"
        case .stale: return "Stale"
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        case .skipped: return "arrow.right.circle.fill"
        case .timedOut: return "clock.badge.exclamationmark.fill"
        case .actionRequired: return "exclamationmark.triangle.fill"
        case .neutral: return "minus.circle.fill"
        case .stale: return "clock.badge.questionmark.fill"
        }
    }
    
    var color: String {
        switch self {
        case .success: return "statusGreen"
        case .failure, .timedOut: return "statusRed"
        case .cancelled, .stale: return "statusGray"
        case .skipped, .neutral: return "statusGray"
        case .actionRequired: return "statusYellow"
        }
    }
}

/// Aggregate status for the menu bar icon
enum AggregateStatus {
    case allPassing
    case someRunning
    case someFailing
    case noData
    case error
    
    var icon: String {
        switch self {
        case .allPassing: return "checkmark.circle.fill"
        case .someRunning: return "arrow.triangle.2.circlepath.circle.fill"
        case .someFailing: return "exclamationmark.circle.fill"
        case .noData: return "circle.dashed"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .allPassing: return "statusGreen"
        case .someRunning: return "statusYellow"
        case .someFailing: return "statusRed"
        case .noData: return "statusGray"
        case .error: return "statusOrange"
        }
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        }
        return "Just now"
    }
}
