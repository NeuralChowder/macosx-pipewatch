import Foundation

enum WorkflowStatus: String, Codable {
    case success
    case failure
    case inProgress = "in_progress"
    case unknown
}

struct WorkflowRun: Codable, Identifiable {
    let id: Int
    let name: String
    let status: WorkflowStatus
    let conclusion: String?
    let htmlURL: String
    let createdAt: Date
    let updatedAt: Date
    let headBranch: String
    let event: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case conclusion
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case headBranch = "head_branch"
        case event
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        htmlURL = try container.decode(String.self, forKey: .htmlURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        headBranch = try container.decode(String.self, forKey: .headBranch)
        event = try container.decode(String.self, forKey: .event)
        
        // Parse status
        let statusString = try container.decode(String.self, forKey: .status)
        let conclusionString = try container.decodeIfPresent(String.self, forKey: .conclusion)
        conclusion = conclusionString
        
        // Determine final status based on status and conclusion
        if statusString == "completed" {
            if conclusionString == "success" {
                status = .success
            } else if conclusionString == "failure" {
                status = .failure
            } else {
                status = .unknown
            }
        } else if statusString == "in_progress" || statusString == "queued" {
            status = .inProgress
        } else {
            status = .unknown
        }
    }
}

struct WorkflowRunsResponse: Codable {
    let totalCount: Int
    let workflowRuns: [WorkflowRun]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflowRuns = "workflow_runs"
    }
}

struct Repository: Codable, Identifiable, Equatable {
    let id: UUID
    let owner: String
    let name: String
    
    var fullName: String {
        "\(owner)/\(name)"
    }
    
    init(owner: String, name: String) {
        self.id = UUID()
        self.owner = owner
        self.name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case name
    }
    
    static func == (lhs: Repository, rhs: Repository) -> Bool {
        lhs.owner == rhs.owner && lhs.name == rhs.name
    }
}
