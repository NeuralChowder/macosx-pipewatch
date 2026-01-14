import Foundation

protocol GitHubServiceDelegate: AnyObject {
    func didUpdateWorkflows(_ workflows: [WorkflowRun])
    func didFailWithError(_ error: Error)
}

class GitHubService {
    private let token: String
    private let session: URLSession
    private var repositories: [Repository] = []
    private let maxRepositoryCount = 10
    private let syncQueue = DispatchQueue(label: "com.pipewatch.github-service", attributes: .concurrent)
    weak var delegate: GitHubServiceDelegate?
    
    init(token: String) {
        self.token = token
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // Load repositories from UserDefaults
        loadRepositories()
    }
    
    func fetchWorkflowRuns() {
        guard !repositories.isEmpty else {
            // If no repositories configured, try to fetch user's repositories
            fetchUserRepositories()
            return
        }
        
        var allWorkflows: [WorkflowRun] = []
        let workflowsLock = NSLock()
        let group = DispatchGroup()
        
        for repo in repositories {
            group.enter()
            fetchWorkflowRuns(for: repo) { workflows in
                workflowsLock.lock()
                allWorkflows.append(contentsOf: workflows)
                workflowsLock.unlock()
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            // Keep only the latest run per workflow name
            let latestWorkflows = self?.filterLatestWorkflows(allWorkflows) ?? []
            self?.delegate?.didUpdateWorkflows(latestWorkflows)
        }
    }
    
    private func fetchWorkflowRuns(for repo: Repository, completion: @escaping ([WorkflowRun]) -> Void) {
        let urlString = "https://api.github.com/repos/\(repo.owner)/\(repo.name)/actions/runs?per_page=100"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching workflows for \(repo.fullName): \(error)")
                completion([])
                return
            }
            
            guard let data = data else {
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode(WorkflowRunsResponse.self, from: data)
                completion(response.workflowRuns)
            } catch {
                print("Error decoding workflow runs: \(error)")
                completion([])
            }
        }
        
        task.resume()
    }
    
    private func filterLatestWorkflows(_ workflows: [WorkflowRun]) -> [WorkflowRun] {
        var latestWorkflows: [String: WorkflowRun] = [:]
        
        for workflow in workflows {
            let key = workflow.workflowKey
            if let existing = latestWorkflows[key] {
                // Keep the most recent one
                if workflow.updatedAt > existing.updatedAt {
                    latestWorkflows[key] = workflow
                }
            } else {
                latestWorkflows[key] = workflow
            }
        }
        
        return Array(latestWorkflows.values).sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func fetchUserRepositories() {
        let urlString = "https://api.github.com/user/repos?per_page=100&sort=updated"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                if let error = error {
                    DispatchQueue.main.async {
                        self?.delegate?.didFailWithError(error)
                    }
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                if let repos = try? decoder.decode([GitHubRepository].self, from: data) {
                    let repositories = repos.map { Repository(owner: $0.owner.login, name: $0.name) }
                    self?.repositories = Array(repositories.prefix(self?.maxRepositoryCount ?? 10))
                    self?.saveRepositories()
                    
                    // Now fetch workflows
                    DispatchQueue.main.async {
                        self?.fetchWorkflowRuns()
                    }
                }
            }
        }
        
        task.resume()
    }
    
    private func loadRepositories() {
        if let data = UserDefaults.standard.data(forKey: "repositories"),
           let repos = try? JSONDecoder().decode([Repository].self, from: data) {
            repositories = repos
        }
    }
    
    private func saveRepositories() {
        if let data = try? JSONEncoder().encode(repositories) {
            UserDefaults.standard.set(data, forKey: "repositories")
        }
    }
    
    func addRepository(_ repo: Repository) {
        if !repositories.contains(where: { $0.owner == repo.owner && $0.name == repo.name }) {
            repositories.append(repo)
            saveRepositories()
        }
    }
    
    func removeRepository(_ repo: Repository) {
        repositories.removeAll { $0.owner == repo.owner && $0.name == repo.name }
        saveRepositories()
    }
}

// Helper struct for API response
private struct GitHubRepository: Codable {
    let name: String
    let owner: Owner
    
    struct Owner: Codable {
        let login: String
    }
}
