import SwiftUI
import Combine

/// Central app state managing authentication and user preferences
@MainActor
class AppState: ObservableObject {
    @Published var accounts: [ProviderAccount] = []
    @Published var selectedOrganizations: [String] = []
    @Published var isAuthenticated: Bool = false
    @Published var refreshInterval: TimeInterval = 60
    @Published var showNotifications: Bool = true
    @Published var filterDays: Int = 3
    
    private let settingsRepository = SettingsRepository()
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        Task {
            do {
                let settings = try await settingsRepository.loadSettings()
                self.accounts = settings.accounts
                self.selectedOrganizations = settings.selectedOrganizations
                self.refreshInterval = settings.refreshInterval
                self.showNotifications = settings.showNotifications
                self.filterDays = settings.filterDays
                self.isAuthenticated = !accounts.isEmpty
            } catch {
                print("Failed to load settings: \(error)")
            }
        }
    }
    
    func saveSettings() {
        Task {
            do {
                let settings = AppSettings(
                    accounts: accounts,
                    selectedOrganizations: selectedOrganizations,
                    refreshInterval: refreshInterval,
                    showNotifications: showNotifications,
                    filterDays: filterDays
                )
                try await settingsRepository.saveSettings(settings)
            } catch {
                print("Failed to save settings: \(error)")
            }
        }
    }
    
    func addAccount(_ account: ProviderAccount) {
        accounts.append(account)
        isAuthenticated = true
        saveSettings()
    }
    
    func removeAccount(_ account: ProviderAccount) {
        accounts.removeAll { $0.id == account.id }
        isAuthenticated = !accounts.isEmpty
        
        // Remove token from keychain
        Task {
            try? await KeychainService.shared.deleteToken(for: account.id)
        }
        saveSettings()
    }
    
    func updateSelectedOrganizations(_ orgs: [String]) {
        selectedOrganizations = orgs
        saveSettings()
    }
}

/// App settings model
struct AppSettings: Codable {
    var accounts: [ProviderAccount]
    var selectedOrganizations: [String]
    var refreshInterval: TimeInterval
    var showNotifications: Bool
    var filterDays: Int
    
    init(
        accounts: [ProviderAccount] = [],
        selectedOrganizations: [String] = [],
        refreshInterval: TimeInterval = 60,
        showNotifications: Bool = true,
        filterDays: Int = 3
    ) {
        self.accounts = accounts
        self.selectedOrganizations = selectedOrganizations
        self.refreshInterval = refreshInterval
        self.showNotifications = showNotifications
        self.filterDays = filterDays
    }
}

/// Provider account model
struct ProviderAccount: Identifiable, Codable, Hashable {
    let id: String
    let provider: ProviderType
    let username: String
    let avatarURL: URL?
    let createdAt: Date
    
    init(id: String = UUID().uuidString, provider: ProviderType, username: String, avatarURL: URL? = nil) {
        self.id = id
        self.provider = provider
        self.username = username
        self.avatarURL = avatarURL
        self.createdAt = Date()
    }
}

/// Supported CI/CD providers
enum ProviderType: String, Codable, CaseIterable {
    case github = "GitHub"
    case gitlab = "GitLab"       // Future support
    case bitbucket = "Bitbucket" // Future support
    
    var icon: String {
        switch self {
        case .github: return "github.mark"
        case .gitlab: return "gitlab.mark"
        case .bitbucket: return "bitbucket.mark"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .github: return "person.crop.circle.badge.checkmark"
        case .gitlab: return "person.crop.circle.badge.checkmark"
        case .bitbucket: return "person.crop.circle.badge.checkmark"
        }
    }
}
