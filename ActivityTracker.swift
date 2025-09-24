import Cocoa

// MARK: - Activity Tracker
class ActivityTracker {
    static let shared = ActivityTracker()
    
    // Activity state
    private(set) var currentActivityType: String?
    private(set) var currentStartTime: Date?
    private(set) var isInBreak = false
    
    // Timers
    private var timer: Timer?
    private var idleTimer: Timer?
    private var lastActivityTime: Date = Date()
    private var idleState: IdleState = .active
    
    // Event monitoring
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    // Idle tracking
    private var idleStartTime: Date?
    private var returnDialogShownTime: Date?
    private var autoEndTimer: Timer?
    
    // Data management
    private let dataManager = DataManager.shared
    private let preferences = TimeDeckPreferences.shared
    
    private init() {}
    
    // MARK: - Activity Management
    func startActivity(name: String) {
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        currentActivityType = name
        currentStartTime = Date()
        
        // Reset idle tracking for new activity
        lastActivityTime = Date()
        idleState = .active
        
        dataManager.logActivity(.start, activityName: name)
        NotificationManager.shared.showNotification(title: "🎯 Activity Started", message: "Started tracking \(name)")
        
        // Notify UI to update
        NotificationCenter.default.post(name: NSNotification.Name("ActivityStateChanged"), object: nil)
    }
    
    func quickStartActivity(name: String) {
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        currentActivityType = name
        currentStartTime = Date()
        
        // Reset idle tracking for new activity
        lastActivityTime = Date()
        idleState = .active
        
        dataManager.logActivity(.quickStart, activityName: name)
        NotificationManager.shared.showNotification(title: "🚀 Quick Start", message: "Started \(name)")
        
        // Notify UI to update
        NotificationCenter.default.post(name: NSNotification.Name("ActivityStateChanged"), object: nil)
    }
    
    func pauseResumeActivity() {
        guard let currentActivity = currentActivityType else { return }
        
        if isInBreak {
            dataManager.logActivity(.resume, activityName: currentActivity)
            isInBreak = false
            NotificationManager.shared.showNotification(title: "▶️ Resumed", message: "Back to \(currentActivity)")
        } else {
            dataManager.logActivity(.pause, activityName: currentActivity)
            isInBreak = true
            NotificationManager.shared.showNotification(title: "⏸️ Paused", message: "Taking a break from \(currentActivity)")
        }
        
        // Notify UI to update
        NotificationCenter.default.post(name: NSNotification.Name("ActivityStateChanged"), object: nil)
    }
    
    func endCurrentActivity() {
        guard let currentActivity = currentActivityType,
              let startTime = currentStartTime else {
            AlertManager.shared.showAlert(
                type: .info,
                title: "No Active Activity",
                message: "There's no activity currently being tracked."
            )
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        dataManager.logActivity(.end, activityName: currentActivity, duration: duration)
        
        currentActivityType = nil
        currentStartTime = nil
        isInBreak = false
        
        NotificationManager.shared.showNotification(
            title: "✅ Activity Ended", 
            message: "\(currentActivity) completed (\(hours)h \(minutes)m)",
            fallbackToAlert: true  // Important notification
        )
        
        // Notify UI to update
        NotificationCenter.default.post(name: NSNotification.Name("ActivityStateChanged"), object: nil)
    }
    
    func endDay() {
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        dataManager.logActivity(.dayEnd)
        NotificationManager.shared.showNotification(title: "🌅 Day Complete", message: "Great work today! All activities logged.")
    }
    
    func startFresh() {
        currentActivityType = nil
        currentStartTime = nil
        isInBreak = false
        
        // Clear log files natively instead of AppleScript
        clearActivityLogs()
        
        // Notify UI to update
        NotificationCenter.default.post(name: NSNotification.Name("ActivityStateChanged"), object: nil)
    }
    
    private func clearActivityLogs() {
        // Clear all activity data using DataManager
        dataManager.clearAllData()
        
        // Log the fresh start
        dataManager.logActivity(.freshStart)
        NotificationManager.shared.showNotification(title: "🧹 Fresh Start", message: "All activity logs cleared. Ready for a new session!")
    }
    
    // MARK: - Activity Status
    func getCurrentActivityInfo() -> (activity: String, timeString: String)? {
        guard let currentActivity = currentActivityType,
              let startTime = currentStartTime else {
            return nil
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) % 3600 / 60
        let timeString = String(format: "%d:%02d", hours, minutes)
        
        return (currentActivity, timeString)
    }
    
    // MARK: - Recent Activities
    func getRecentActivities(limit: Int) -> [String] {
        return dataManager.getRecentActivities(limit: limit)
    }
    
    // MARK: - Idle Detection
    func startIdleDetection() {
        guard preferences.idleDetectionEnabled else { return }
        
        // Start timer to check idle state every 30 seconds
        idleTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.checkIdleState()
        }
        
        // Start monitoring user input events
        startEventMonitoring()
    }
    
    func stopIdleDetection() {
        idleTimer?.invalidate()
        idleTimer = nil
        stopEventMonitoring()
    }
    
    private func startEventMonitoring() {
        // Monitor global events (when app is not focused)
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .keyDown, .keyUp,
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged,
            .scrollWheel
        ]) { [weak self] _ in
            self?.recordUserActivity()
        }
        
        // Monitor local events (when app is focused)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .keyDown, .keyUp,
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged,
            .scrollWheel
        ]) { [weak self] event in
            self?.recordUserActivity()
            return event
        }
    }
    
    private func stopEventMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    private func checkIdleState() {
        let now = Date()
        let timeSinceLastActivity = now.timeIntervalSince(lastActivityTime)
        let idleThresholdSeconds = TimeInterval(preferences.idleTimeoutMinutes * 60)
        
        switch idleState {
        case .active:
            if timeSinceLastActivity > idleThresholdSeconds {
                // User has gone idle
                idleStartTime = lastActivityTime.addingTimeInterval(idleThresholdSeconds)
                handleIdleDetected()
            }
        case .idle:
            // Wait for user activity to trigger return from idle
            break
        case .returning:
            // Dialog is shown, check for auto-end timeout
            if let dialogTime = returnDialogShownTime {
                let dialogAge = now.timeIntervalSince(dialogTime)
                let autoEndThreshold = TimeInterval(preferences.autoEndTimeoutMinutes * 60)
                
                if dialogAge > autoEndThreshold {
                    handleAutoEndActivity()
                }
            }
        }
        
        // Note: lastActivityTime is only updated by recordUserActivity() when real events occur
    }
    
    private func handleIdleDetected() {
        idleState = .idle
        
        if let currentActivity = currentActivityType {
            dataManager.logActivity(.idleDetected, activityName: currentActivity)
            // Don't show notification immediately - wait for return
        }
    }
    
    private func handleReturnFromIdle() {
        guard let currentActivity = currentActivityType else {
            idleState = .active
            return
        }
        
        idleState = .returning
        returnDialogShownTime = Date()
        
        // Log the return
        dataManager.logActivity(.returnFromIdle, activityName: currentActivity)
        
        // Show return dialog
        showReturnFromIdleDialog(currentActivity: currentActivity)
    }
    
    private func showReturnFromIdleDialog(currentActivity: String) {
        DispatchQueue.main.async {
            let idleMinutes = self.getIdleDurationMinutes()
            
            let alert = NSAlert()
            alert.messageText = "⏰ Welcome Back!"
            alert.informativeText = """
            You were working on: "\(currentActivity)"
            Away for: \(idleMinutes) minutes
            
            What would you like to do?
            """
            
            alert.addButton(withTitle: "▶️ Continue \(currentActivity)")
            alert.addButton(withTitle: "⏹️ End \(currentActivity)")
            alert.addButton(withTitle: "🆕 Start New Activity")
            alert.addButton(withTitle: "☕ I was on a break")
            
            let response = alert.runModal()
            self.handleReturnDialogResponse(response, currentActivity: currentActivity)
        }
    }
    
    private func handleReturnDialogResponse(_ response: NSApplication.ModalResponse, currentActivity: String) {
        // Clear dialog state
        returnDialogShownTime = nil
        autoEndTimer?.invalidate()
        autoEndTimer = nil
        
        switch response {
        case .alertFirstButtonReturn:  // Continue
            idleState = .active
            NotificationManager.shared.showNotification(
                title: "▶️ Continuing", 
                message: "Resumed \(currentActivity)"
            )
            
        case .alertSecondButtonReturn:  // End activity
            endCurrentActivity()
            
        case .alertThirdButtonReturn:  // Start new activity
            endCurrentActivity()
            // Trigger new activity dialog
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("ShowNewActivityDialog"), object: nil)
            }
            
        default:  // Break or cancel
            // Log as break time and end current activity
            if let idleStart = idleStartTime {
                let breakDuration = Date().timeIntervalSince(idleStart)
                dataManager.logActivity(.pause, activityName: "Break", duration: breakDuration)
            }
            endCurrentActivity()
        }
        
        // Clear idle tracking
        idleStartTime = nil
    }
    
    private func handleAutoEndActivity() {
        guard let currentActivity = currentActivityType,
              let idleStart = idleStartTime else { return }
        
        // End the activity with backdated time to when idle was first detected
        let duration = idleStart.timeIntervalSince(currentStartTime ?? idleStart)
        
        dataManager.logActivity(.end, activityName: currentActivity, duration: duration)
        
        currentActivityType = nil
        currentStartTime = nil
        isInBreak = false
        idleState = .active
        
        // Clear timers and state
        autoEndTimer?.invalidate()
        autoEndTimer = nil
        returnDialogShownTime = nil
        idleStartTime = nil
        
        NotificationManager.shared.showNotification(
            title: "⏰ Auto-Ended Activity",
            message: "\(currentActivity) ended automatically (backdated to when you left)",
            fallbackToAlert: true  // Important notification - show alert if notifications disabled
        )
        
        // Notify UI to update
        NotificationCenter.default.post(name: NSNotification.Name("ActivityStateChanged"), object: nil)
    }
    
    private func getIdleDurationMinutes() -> Int {
        guard let idleStart = idleStartTime else { return 0 }
        let duration = Date().timeIntervalSince(idleStart)
        return Int(duration / 60)
    }
    
    // MARK: - User Activity Tracking
    func recordUserActivity() {
        let now = Date()
        
        // Only update if there's been a significant gap (avoid spam from mouse movements)
        if now.timeIntervalSince(lastActivityTime) > 10.0 {
            lastActivityTime = now
        } else {
            // For frequent events, just update the time without other logic
            lastActivityTime = now
        }
        
        // If we're in idle state and user becomes active, trigger return
        if idleState == .idle {
            handleReturnFromIdle()
        }
    }
    
    func manuallyTriggerIdleDetection() {
        // Allow manual triggering of idle detection (for testing or user request)
        if idleState == .active && currentActivityType != nil {
            idleStartTime = Date()
            handleIdleDetected()
            handleReturnFromIdle()
        }
    }
    
    // MARK: - Data Access (for backward compatibility)
    func getDataDirectoryPath() -> String {
        return dataManager.dataDirectoryPath
    }
    
    func getCurrentLogFilePath() -> String {
        return dataManager.currentLogFilePath
    }
    
    func getDataSizeInfo() -> (totalFiles: Int, totalSize: String) {
        return dataManager.getDataSizeInfo()
    }
    
    // MARK: - Cleanup
    func cleanup() {
        timer?.invalidate()
        idleTimer?.invalidate()
        autoEndTimer?.invalidate()
        
        // Stop event monitoring
        stopEventMonitoring()
        
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        // Clear idle state
        idleStartTime = nil
        returnDialogShownTime = nil
        idleState = .active
    }
}
