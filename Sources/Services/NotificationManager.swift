import Foundation
import UserNotifications
import AppKit

class NotificationManager: NSObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var previousStates: [String: WorkflowStatus] = [:] // workflow name -> status
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func sendNotification(title: String, body: String, url: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["url": url]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Send immediately
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    func checkForFailuresAndNotify(workflows: [WorkflowRun]) {
        for workflow in workflows {
            let previousStatus = previousStates[workflow.name]
            
            // Check for new failure
            if workflow.status == .failure && previousStatus != .failure {
                sendNotification(
                    title: "Build Failed ❌",
                    body: "\(workflow.name) on \(workflow.headBranch)",
                    url: workflow.htmlURL
                )
            }
            
            // Check for recovery
            if workflow.status == .success && previousStatus == .failure {
                sendNotification(
                    title: "Build Recovered ✅",
                    body: "\(workflow.name) on \(workflow.headBranch) is now passing",
                    url: workflow.htmlURL
                )
            }
            
            // Update state
            previousStates[workflow.name] = workflow.status
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap - open URL in browser
        if let urlString = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
