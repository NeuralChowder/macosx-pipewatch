import Foundation
import UserNotifications

/// Service for managing macOS notifications
class NotificationService {
    private var isAuthorized = false
    
    init() {
        // Don't request authorization in init - defer until actually needed
    }
    
    // MARK: - Authorization
    
    func requestAuthorizationIfNeeded() {
        guard !isAuthorized else { return }
        guard Bundle.main.bundleIdentifier != nil else {
            // Running outside of a proper app bundle (e.g., swift run)
            print("Notifications not available outside app bundle")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            self?.isAuthorized = granted
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    // MARK: - Notifications
    
    private var canSendNotifications: Bool {
        Bundle.main.bundleIdentifier != nil
    }
    
    func sendFailureNotification(for run: PipelineRun) {
        guard canSendNotifications else { return }
        requestAuthorizationIfNeeded()
        
        let content = UNMutableNotificationContent()
        content.title = "❌ Pipeline Failed"
        content.subtitle = run.repository.name
        content.body = "\(run.name) on \(run.branch) has failed"
        content.sound = .default
        content.categoryIdentifier = "PIPELINE_FAILURE"
        content.userInfo = ["runId": run.id, "url": run.url.absoluteString]
        
        let request = UNNotificationRequest(
            identifier: "failure-\(run.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendRecoveryNotification(for run: PipelineRun) {
        guard canSendNotifications else { return }
        requestAuthorizationIfNeeded()
        
        let content = UNMutableNotificationContent()
        content.title = "✅ Pipeline Recovered"
        content.subtitle = run.repository.name
        content.body = "\(run.name) on \(run.branch) is now passing"
        content.sound = .default
        content.categoryIdentifier = "PIPELINE_RECOVERY"
        content.userInfo = ["runId": run.id, "url": run.url.absoluteString]
        
        let request = UNNotificationRequest(
            identifier: "recovery-\(run.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendRunningNotification(for run: PipelineRun) {
        guard canSendNotifications else { return }
        requestAuthorizationIfNeeded()
        
        let content = UNMutableNotificationContent()
        content.title = "🔄 Pipeline Started"
        content.subtitle = run.repository.name
        content.body = "\(run.name) on \(run.branch) is now running"
        content.sound = .default
        content.categoryIdentifier = "PIPELINE_RUNNING"
        content.userInfo = ["runId": run.id, "url": run.url.absoluteString]
        
        let request = UNNotificationRequest(
            identifier: "running-\(run.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Notification Actions
    
    func setupNotificationCategories() {
        guard canSendNotifications else { return }
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View in Browser",
            options: [.foreground]
        )
        
        let rerunAction = UNNotificationAction(
            identifier: "RERUN_ACTION",
            title: "Rerun",
            options: []
        )
        
        let failureCategory = UNNotificationCategory(
            identifier: "PIPELINE_FAILURE",
            actions: [viewAction, rerunAction],
            intentIdentifiers: []
        )
        
        let recoveryCategory = UNNotificationCategory(
            identifier: "PIPELINE_RECOVERY",
            actions: [viewAction],
            intentIdentifiers: []
        )
        
        let runningCategory = UNNotificationCategory(
            identifier: "PIPELINE_RUNNING",
            actions: [viewAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            failureCategory,
            recoveryCategory,
            runningCategory
        ])
    }
}
