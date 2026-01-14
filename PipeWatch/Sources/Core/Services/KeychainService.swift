import Foundation
import KeychainAccess

/// Service for securely storing and retrieving tokens from the macOS Keychain
actor KeychainService {
    static let shared = KeychainService()
    
    private let keychain: Keychain
    private let serviceIdentifier = "com.PipeWatch.tokens"
    
    private init() {
        self.keychain = Keychain(service: serviceIdentifier)
            .accessibility(.afterFirstUnlock)
    }
    
    // MARK: - Token Management
    
    /// Store a token for an account
    func storeToken(_ token: String, for accountId: String) async throws {
        try keychain.set(token, key: tokenKey(for: accountId))
    }
    
    /// Retrieve a token for an account
    func getToken(for accountId: String) async throws -> String? {
        return try keychain.get(tokenKey(for: accountId))
    }
    
    /// Delete a token for an account
    func deleteToken(for accountId: String) async throws {
        try keychain.remove(tokenKey(for: accountId))
    }
    
    /// Check if a token exists for an account
    func hasToken(for accountId: String) async -> Bool {
        do {
            return try keychain.get(tokenKey(for: accountId)) != nil
        } catch {
            return false
        }
    }
    
    /// Delete all stored tokens
    func deleteAllTokens() async throws {
        try keychain.removeAll()
    }
    
    // MARK: - Helpers
    
    private func tokenKey(for accountId: String) -> String {
        return "token-\(accountId)"
    }
}
