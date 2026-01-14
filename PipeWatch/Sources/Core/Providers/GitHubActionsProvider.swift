import Foundation

/// GitHub Actions provider implementation
class GitHubActionsProvider: CIProvider {
    let name = "GitHub Actions"
    let providerType = ProviderType.github
    
    private let baseURL = "https://api.github.com"
    private let apiClient: APIClient
    
    init() {
        self.apiClient = APIClient(baseURL: baseURL)
    }
    
    // MARK: - Authentication
    
    func validateToken(_ token: String) async throws -> ProviderAccount {
        let response: GitHubUser = try await apiClient.get(
            "/user",
            headers: authHeaders(token: token)
        )
        
        return ProviderAccount(
            id: "github-\(response.id)",
            provider: .github,
            username: response.login,
            avatarURL: URL(string: response.avatar_url)
        )
    }
    
    // MARK: - Organizations
    
    func fetchOrganizations(token: String) async throws -> [Organization] {
        // First get the authenticated user for personal account
        let user: GitHubUser = try await apiClient.get(
            "/user",
            headers: authHeaders(token: token)
        )
        
        // Get organizations
        let orgs: [GitHubOrganization] = try await apiClient.get(
            "/user/orgs",
            headers: authHeaders(token: token)
        )
        
        // Create personal account org entry
        var organizations: [Organization] = [
            Organization(
                id: "user-\(user.id)",
                name: user.name ?? user.login,
                login: user.login,
                avatarURL: URL(string: user.avatar_url),
                provider: .github,
                isPersonal: true
            )
        ]
        
        // Add actual organizations
        organizations.append(contentsOf: orgs.map { org in
            Organization(
                id: "org-\(org.id)",
                name: org.login,
                login: org.login,
                avatarURL: URL(string: org.avatar_url),
                provider: .github,
                isPersonal: false
            )
        })
        
        return organizations
    }
    
    // MARK: - Repositories
    
    func fetchRepositories(token: String, organizations: [String]) async throws -> [Repository] {
        var allRepos: [Repository] = []
        
        for org in organizations {
            do {
                // Try fetching as organization repos first
                let repos: [GitHubRepository] = try await apiClient.get(
                    "/orgs/\(org)/repos",
                    queryItems: ["per_page": "100", "sort": "pushed"],
                    headers: authHeaders(token: token)
                )
                allRepos.append(contentsOf: repos.map { $0.toRepository() })
            } catch {
                // Fall back to user repos if org fetch fails (might be personal account)
                let repos: [GitHubRepository] = try await apiClient.get(
                    "/users/\(org)/repos",
                    queryItems: ["per_page": "100", "sort": "pushed"],
                    headers: authHeaders(token: token)
                )
                allRepos.append(contentsOf: repos.map { $0.toRepository() })
            }
        }
        
        return allRepos
    }
    
    // MARK: - Pipeline Runs
    
    func fetchPipelineRuns(token: String, repository: Repository) async throws -> [PipelineRun] {
        let response: GitHubWorkflowRunsResponse = try await apiClient.get(
            "/repos/\(repository.fullName)/actions/runs",
            queryItems: ["per_page": "30"],
            headers: authHeaders(token: token)
        )
        
        return response.workflow_runs.map { $0.toPipelineRun(repository: repository) }
    }
    
    func fetchAllPipelineRuns(token: String, organizations: [String], since: Date) async throws -> [PipelineRun] {
        var allRuns: [PipelineRun] = []
        let dateFormatter = ISO8601DateFormatter()
        let sinceString = dateFormatter.string(from: since)
        
        // Fetch repositories and their runs in parallel
        let repositories = try await fetchRepositories(token: token, organizations: organizations)
        
        // Use TaskGroup for parallel fetching
        try await withThrowingTaskGroup(of: [PipelineRun].self) { group in
            for repo in repositories {
                group.addTask {
                    do {
                        let response: GitHubWorkflowRunsResponse = try await self.apiClient.get(
                            "/repos/\(repo.fullName)/actions/runs",
                            queryItems: [
                                "per_page": "30",
                                "created": ">=\(sinceString)"
                            ],
                            headers: self.authHeaders(token: token)
                        )
                        return response.workflow_runs.map { $0.toPipelineRun(repository: repo) }
                    } catch {
                        // Return empty array if repo has no actions or access denied
                        return []
                    }
                }
            }
            
            for try await runs in group {
                allRuns.append(contentsOf: runs)
            }
        }
        
        // Sort by most recent first
        return allRuns.sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }
    
    func getPipelineURL(_ run: PipelineRun) -> URL {
        return run.url
    }
    
    // MARK: - Actions
    
    func cancelPipeline(token: String, run: PipelineRun) async throws {
        try await apiClient.post(
            "/repos/\(run.repository.fullName)/actions/runs/\(run.id)/cancel",
            headers: authHeaders(token: token)
        )
    }
    
    func rerunPipeline(token: String, run: PipelineRun) async throws {
        try await apiClient.post(
            "/repos/\(run.repository.fullName)/actions/runs/\(run.id)/rerun",
            headers: authHeaders(token: token)
        )
    }
    
    // MARK: - Helpers
    
    private func authHeaders(token: String) -> [String: String] {
        [
            "Authorization": "Bearer \(token)",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
    }
}

// MARK: - GitHub API Models

struct GitHubUser: Codable {
    let id: Int
    let login: String
    let name: String?
    let avatar_url: String
}

struct GitHubOrganization: Codable {
    let id: Int
    let login: String
    let avatar_url: String
}

struct GitHubRepository: Codable {
    let id: Int
    let name: String
    let full_name: String
    let owner: GitHubOwner
    let html_url: String
    let default_branch: String
    let `private`: Bool
    
    func toRepository() -> Repository {
        Repository(
            id: "github-\(id)",
            name: name,
            fullName: full_name,
            owner: owner.login,
            provider: .github,
            url: URL(string: html_url)!,
            defaultBranch: default_branch,
            isPrivate: `private`
        )
    }
}

struct GitHubOwner: Codable {
    let login: String
}

struct GitHubWorkflowRunsResponse: Codable {
    let total_count: Int
    let workflow_runs: [GitHubWorkflowRun]
}

struct GitHubWorkflowRun: Codable {
    let id: Int
    let name: String?
    let status: String
    let conclusion: String?
    let head_branch: String
    let head_sha: String
    let display_title: String
    let created_at: String
    let updated_at: String
    let html_url: String
    let workflow_id: Int
    let triggering_actor: GitHubActor?
    
    func toPipelineRun(repository: Repository) -> PipelineRun {
        let dateFormatter = ISO8601DateFormatter()
        
        return PipelineRun(
            id: String(id),
            name: name ?? "Workflow",
            status: PipelineStatus(rawValue: status) ?? .pending,
            conclusion: conclusion.flatMap { PipelineConclusion(rawValue: $0) },
            branch: head_branch,
            commitSHA: head_sha,
            commitMessage: display_title,
            startedAt: dateFormatter.date(from: created_at),
            updatedAt: dateFormatter.date(from: updated_at),
            url: URL(string: html_url)!,
            repository: repository,
            triggeredBy: triggering_actor?.login ?? "Unknown",
            workflowId: String(workflow_id)
        )
    }
}

struct GitHubActor: Codable {
    let login: String
}
