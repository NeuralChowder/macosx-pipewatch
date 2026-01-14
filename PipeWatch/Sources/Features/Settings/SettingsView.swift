import SwiftUI

/// Settings view for managing accounts and preferences
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipelineMonitor: PipelineMonitor
    
    var body: some View {
        TabView {
            AccountsSettingsView()
                .tabItem {
                    Label("Accounts", systemImage: "person.crop.circle")
                }
                .environmentObject(appState)
            
            OrganizationsSettingsView()
                .tabItem {
                    Label("Organizations", systemImage: "building.2")
                }
                .environmentObject(appState)
            
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .environmentObject(appState)
                .environmentObject(pipelineMonitor)
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Accounts Settings

struct AccountsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddAccount = false
    
    var body: some View {
        Form {
            Section {
                if appState.accounts.isEmpty {
                    ContentUnavailableView {
                        Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Add a GitHub account to start monitoring pipelines")
                    } actions: {
                        Button("Add Account") {
                            showAddAccount = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(appState.accounts) { account in
                        AccountRowView(account: account)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            appState.removeAccount(appState.accounts[index])
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Connected Accounts")
                    Spacer()
                    Button {
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showAddAccount) {
            AddAccountView()
                .environmentObject(appState)
        }
    }
}

struct AccountRowView: View {
    let account: ProviderAccount
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            if let avatarURL = account.avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.username)
                    .font(.headline)
                
                Text(account.provider.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive) {
                appState.removeAccount(account)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Account View

struct AddAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProvider: ProviderType = .github
    @State private var token = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("Add Account")
                    .font(.title2.weight(.semibold))
                
                Text("Connect your Git provider to monitor pipelines")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            
            Divider()
            
            // Provider selection
            Form {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(ProviderType.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .disabled(selectedProvider != .github) // Only GitHub for now
                
                Section {
                    SecureField("Personal Access Token", text: $token)
                        .textFieldStyle(.roundedBorder)
                    
                    if selectedProvider == .github {
                        Link(destination: URL(string: "https://github.com/settings/tokens?type=beta")!) {
                            Label("Create a token on GitHub", systemImage: "arrow.up.right.square")
                                .font(.caption)
                        }
                        
                        Text("Required scopes: repo, read:org")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Authentication")
                }
                
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button {
                    validateAndAddAccount()
                } label: {
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Add Account")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(token.isEmpty || isValidating)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 450)
    }
    
    private func validateAndAddAccount() {
        isValidating = true
        errorMessage = nil
        
        Task {
            do {
                let provider = GitHubActionsProvider()
                let account = try await provider.validateToken(token)
                
                // Store token securely
                try await KeychainService.shared.storeToken(token, for: account.id)
                
                // Add account to app state
                await MainActor.run {
                    appState.addAccount(account)
                    dismiss()
                }
            } catch let error as APIError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isValidating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to validate token: \(error.localizedDescription)"
                    isValidating = false
                }
            }
        }
    }
}

// MARK: - Organizations Settings

struct OrganizationsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var organizations: [Organization] = []
    @State private var selectedOrgs: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            if appState.accounts.isEmpty {
                ContentUnavailableView {
                    Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
                } description: {
                    Text("Add an account first to select organizations")
                }
            } else if isLoading {
                ProgressView("Loading organizations...")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        loadOrganizations()
                    }
                }
            } else {
                Section {
                    ForEach(organizations) { org in
                        Toggle(isOn: binding(for: org.login)) {
                            HStack(spacing: 12) {
                                if let avatarURL = org.avatarURL {
                                    AsyncImage(url: avatarURL) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(systemName: org.isPersonal ? "person.circle" : "building.2")
                                    }
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(org.name)
                                    if org.isPersonal {
                                        Text("Personal")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select organizations to monitor")
                } footer: {
                    Text("Only repositories from selected organizations will be monitored")
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            selectedOrgs = Set(appState.selectedOrganizations)
            loadOrganizations()
        }
        .onChange(of: selectedOrgs) { _, newValue in
            appState.updateSelectedOrganizations(Array(newValue))
        }
    }
    
    private func binding(for login: String) -> Binding<Bool> {
        Binding(
            get: { selectedOrgs.contains(login) },
            set: { isSelected in
                if isSelected {
                    selectedOrgs.insert(login)
                } else {
                    selectedOrgs.remove(login)
                }
            }
        )
    }
    
    private func loadOrganizations() {
        guard let account = appState.accounts.first else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let token = try await KeychainService.shared.getToken(for: account.id) else {
                    throw PipelineError.noToken
                }
                
                let provider = GitHubActionsProvider()
                let orgs = try await provider.fetchOrganizations(token: token)
                
                await MainActor.run {
                    organizations = orgs
                    // Auto-select personal account if nothing is selected
                    if selectedOrgs.isEmpty, let personal = orgs.first(where: { $0.isPersonal }) {
                        selectedOrgs.insert(personal.login)
                        appState.updateSelectedOrganizations([personal.login])
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipelineMonitor: PipelineMonitor
    
    var body: some View {
        Form {
            Section {
                Picker("Refresh interval", selection: $appState.refreshInterval) {
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                    Text("2 minutes").tag(120.0)
                    Text("5 minutes").tag(300.0)
                }
                
                Picker("Show pipelines from", selection: $appState.filterDays) {
                    Text("Last 24 hours").tag(1)
                    Text("Last 3 days").tag(3)
                    Text("Last 7 days").tag(7)
                    Text("Last 14 days").tag(14)
                }
            } header: {
                Text("Refresh")
            }
            
            Section {
                Toggle("Show notifications for failures", isOn: $appState.showNotifications)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get notified when a pipeline fails or recovers")
            }
            
            Section {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Minimum macOS", value: "13.0")
                
                Link(destination: URL(string: "https://github.com")!) {
                    Label("View on GitHub", systemImage: "arrow.up.right.square")
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .onChange(of: appState.refreshInterval) { _, _ in
            appState.saveSettings()
            pipelineMonitor.refreshInterval = appState.refreshInterval
        }
        .onChange(of: appState.filterDays) { _, _ in
            appState.saveSettings()
            pipelineMonitor.filterDays = appState.filterDays
            Task {
                await pipelineMonitor.refresh(appState: appState)
            }
        }
        .onChange(of: appState.showNotifications) { _, _ in
            appState.saveSettings()
            pipelineMonitor.showNotifications = appState.showNotifications
        }
    }
}
