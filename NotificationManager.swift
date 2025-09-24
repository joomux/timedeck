import Cocoa
import UserNotifications

// MARK: - Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Notification Setup
    func requestNotificationPermissions() {
        // Notifications disabled for unsigned app - no setup needed
    }
    
    // MARK: - Show Notifications
    func showNotification(title: String, message: String, fallbackToAlert: Bool = false) {
        // Notifications are disabled for unsigned app - always use alert fallback if requested
        if fallbackToAlert {
            DispatchQueue.main.async {
                self.showFallbackAlert(title: title, message: message)
            }
        }
        // Silent failure for regular notifications - app works fine without them
    }
    
    
    
    func requestPermissionsWithUserFeedback() {
        // Notifications disabled for unsigned app - show info instead
        showPermissionAlert(
            "Notifications Disabled",
            """
            Notifications are disabled in this version of TimeDeck.
            
            TimeDeck works perfectly without notifications - all activity tracking, 
            idle detection, and features function normally.
            
            Activity updates will be shown in the menu bar instead.
            """
        )
    }
    
    private func showFallbackAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showPermissionAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        if title.contains("Disabled") || title.contains("Denied") || title.contains("Re-enable") || title.contains("Restricted") {
            alert.addButton(withTitle: "Open System Settings")
        }
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Try multiple approaches to open System Settings
            var opened = false
            
            // Try modern macOS System Settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                opened = NSWorkspace.shared.open(url)
            }
            
            // Fallback to older method
            if !opened {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    opened = NSWorkspace.shared.open(url)
                }
            }
            
            // Final fallback - just open System Settings
            if !opened {
                if let url = URL(string: "x-apple.systempreferences:") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
