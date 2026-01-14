import Foundation
import ServiceManagement

/// Service to manage Launch at Login functionality
@MainActor
class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()
    
    private init() {}
    
    /// Check if launch at login is enabled
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    /// Enable or disable launch at login
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status == .enabled {
                return // Already enabled
            }
            try SMAppService.mainApp.register()
        } else {
            if SMAppService.mainApp.status == .notRegistered {
                return // Already disabled
            }
            try SMAppService.mainApp.unregister()
        }
    }
}
