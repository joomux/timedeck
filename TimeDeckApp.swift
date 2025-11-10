import Cocoa

// MARK: - Main TimeDeck Application
class TimeDeckApp: NSObject, NSApplicationDelegate {
    
    // UI Components
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    // Menu item references for updating
    private var currentActivityMenuItem: NSMenuItem?
    private var currentTimeMenuItem: NSMenuItem?
    
    // Managers
    private let activityTracker = ActivityTracker.shared
    private let templateManager = TemplateManager.shared
    private let analytics = Analytics.shared
    private let notificationManager = NotificationManager.shared
    private let preferences = TimeDeckPreferences.shared
    private let httpServer = HTTPServer.shared
    
    // Timer for menu bar updates
    private var menuBarUpdateTimer: Timer?
    private var iconVisibilityCheckTimer: Timer?
    
    // Cached icon for reuse
    private var cachedMenuBarIcon: NSImage?
    
    // MARK: - Application Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupGlobalKeyboardShortcuts()
        setupNotificationObservers()
        
        // Initialize managers
        notificationManager.requestNotificationPermissions()
        activityTracker.startIdleDetection()
        
        // Start HTTP API server for StreamDeck integration
        httpServer.startServer()
        
        // Start menu bar update timer
        startMenuBarUpdateTimer()
        
        // Start visibility check timer
        startIconVisibilityCheckTimer()
        
        // Welcome message removed - no notifications for unsigned app
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        activityTracker.cleanup()
        httpServer.stopServer()
        menuBarUpdateTimer?.invalidate()
        iconVisibilityCheckTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - URL Scheme Handling for StreamDeck Integration
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURLScheme(url)
        }
    }
    
    private func handleURLScheme(_ url: URL) {
        print("🌐 TimeDeck URL Scheme: \(url.absoluteString)")
        
        guard url.scheme == "timedeck" else {
            print("❌ Invalid URL scheme: \(url.scheme ?? "none")")
            return
        }
        
        let host = url.host?.lowercased() ?? ""
        let _ = url.path
        
        switch host {
        case "start", "new":
            handleStartActivity(from: url)
        case "end", "stop":
            handleEndActivity()
        case "pause", "resume":
            handlePauseResume()
        case "status":
            handleShowStatus()
        case "report":
            handleGenerateReport()
        case "fresh", "reset":
            handleStartFresh()
        case "templates":
            handleManageTemplates()
        case "dialog", "new-dialog":
            handleShowDialog()
        default:
            print("❌ Unknown URL command: \(host)")
            showURLSchemeError("Unknown command: \(host)")
        }
    }
    
    private func handleStartActivity(from url: URL) {
        let path = url.path
        let activityName: String
        
        if path.count > 1 {
            // Remove leading slash and decode URL
            activityName = String(path.dropFirst()).removingPercentEncoding ?? "New Activity"
        } else if url.query != nil {
            // Handle query parameters like ?activity=Development
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            activityName = components?.queryItems?.first(where: { $0.name == "activity" })?.value ?? "New Activity"
        } else {
            activityName = "New Activity"
        }
        
        print("▶️ Starting activity: \(activityName)")
        activityTracker.startActivity(name: activityName)
        notificationManager.showNotification(title: "🚀 StreamDeck", message: "Started '\(activityName)'")
    }
    
    private func handleEndActivity() {
        print("⏹️ Ending current activity")
        activityTracker.endCurrentActivity()
        notificationManager.showNotification(title: "🚀 StreamDeck", message: "Activity ended")
    }
    
    private func handlePauseResume() {
        print("⏸️ Toggling pause/resume")
        // ActivityTracker.pauseResumeActivity() already handles notifications
        activityTracker.pauseResumeActivity()
    }
    
    private func handleShowStatus() {
        print("📊 Showing activity status")
        if let activityInfo = activityTracker.getCurrentActivityInfo() {
            let message = "\(activityInfo.activity)\nTime: \(activityInfo.timeString)"
            showStatusAlert(message)
        } else {
            showStatusAlert("No active activity")
        }
    }
    
    private func handleGenerateReport() {
        print("📄 Generating report")
        analytics.generateReport()
        notificationManager.showNotification(title: "🚀 StreamDeck", message: "Report generated")
    }
    
    private func handleStartFresh() {
        print("🧹 Starting fresh")
        activityTracker.startFresh()
        notificationManager.showNotification(title: "🚀 StreamDeck", message: "Started fresh")
    }
    
    private func handleManageTemplates() {
        print("🏷️ Managing templates")
        templateManager.showManageTemplates()
    }
    
    private func handleShowDialog() {
        print("🎯 Showing enhanced activity dialog")
        showEnhancedActivityDialog()
    }
    
    private func showStatusAlert(_ message: String) {
        AlertManager.shared.showAlert(
            type: .info,
            title: "📊 TimeDeck Status", 
            message: message
        )
    }
    
    private func showURLSchemeError(_ message: String) {
        AlertManager.shared.showAlert(
            type: .error,
            title: "❌ TimeDeck URL Error",
            message: message
        )
    }
    
    // MARK: - Menu Bar Setup
    func setupMenuBar() {
        // Only create statusItem once
        if statusItem == nil {
            print("🎯 Creating menu bar status item for the first time")
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        } else {
            print("✅ Status item already exists, updating it")
        }
        
        updateStatusIcon()
        rebuildMenu()
    }
    
    // MARK: - Status Icon Management
    private func updateStatusIcon() {
        guard let button = statusItem.button else {
            print("⚠️ WARNING: statusItem.button is nil")
            return
        }
        
        // Load icon only once and cache it
        if cachedMenuBarIcon == nil {
            var image: NSImage?
            
            if let iconPath = Bundle.main.path(forResource: "menubar_icon", ofType: "png") {
                print("📍 Found icon at path: \(iconPath)")
                image = NSImage(contentsOfFile: iconPath)
                if image != nil {
                    print("✅ Successfully loaded icon from file")
                } else {
                    print("⚠️ Failed to load icon from file")
                }
            } else {
                print("⚠️ Could not find menubar_icon.png in bundle")
            }
            
            // Fallback to system icon if custom icon fails
            if image == nil {
                print("📍 Using system clock icon fallback")
                image = NSImage(systemSymbolName: "clock", accessibilityDescription: "TimeDeck")
            }
            
            cachedMenuBarIcon = image
        }
        
        // Set the icon
        if let image = cachedMenuBarIcon {
            // Don't use template mode to preserve the colored logo
            image.isTemplate = false
            // Set explicit size for consistency
            image.size = NSSize(width: 18, height: 18)
            button.image = image
            print("✅ Icon set successfully (template mode: false, size: 18x18)")
        }
        
        // Set the title to show current activity alongside icon
        updateMenuBarTitle()
    }
    
    // MARK: - Menu Building
    private func rebuildMenu() {
        print("🔄 Rebuilding menu")
        
        menu = NSMenu()
        
        // Current Activity Section
        if let activityInfo = activityTracker.getCurrentActivityInfo() {
            let pauseIndicator = activityTracker.isInBreak ? " ⏸️" : ""
            currentActivityMenuItem = NSMenuItem(title: "🎯 Current: \(activityInfo.activity)\(pauseIndicator)", action: nil, keyEquivalent: "")
            currentTimeMenuItem = NSMenuItem(title: "⏱️ Time: \(activityInfo.timeString)", action: nil, keyEquivalent: "")
            menu.addItem(currentActivityMenuItem!)
            menu.addItem(currentTimeMenuItem!)
            menu.addItem(NSMenuItem.separator())
        } else {
            currentActivityMenuItem = nil
            currentTimeMenuItem = nil
        }
        
        // Quick Actions Section
        menu.addItem(NSMenuItem(title: "⚡ Quick Actions", action: nil, keyEquivalent: ""))
        let quickTemplates = preferences.activityTemplates.filter { $0.isQuickAction }
        for template in quickTemplates.prefix(8) {
            let item = NSMenuItem(title: "\(template.emoji) \(template.name)", action: #selector(quickStartActivity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = template.name
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        
        // Main Actions
        menu.addItem(NSMenuItem(title: "🆕 New Activity", action: #selector(newActivity), keyEquivalent: ""))
        
        if activityTracker.currentActivityType != nil {
            let pauseTitle = activityTracker.isInBreak ? "▶️ Resume Activity" : "⏸️ Pause Activity"
            menu.addItem(NSMenuItem(title: pauseTitle, action: #selector(pauseResumeActivity), keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem(title: "⏹️ End Activity", action: #selector(endActivity), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "📊 End Day", action: #selector(endDay), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        
        // Analytics & Reports Section
        menu.addItem(NSMenuItem(title: "📈 Analytics & Reports", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "📊 Dashboard", action: #selector(showDashboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "📄 Generate Report", action: #selector(generateReport), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "💾 Export Data", action: #selector(exportData), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Tools Section  
        menu.addItem(NSMenuItem(title: "🔧 Tools", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🏷️ Manage Templates", action: #selector(manageTemplates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🎮 Install StreamDeck Scripts", action: #selector(installStreamDeckScripts), keyEquivalent: ""))
        
        
        menu.addItem(NSMenuItem(title: "⚙️ Preferences", action: #selector(showPreferences), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🧹 Start Fresh", action: #selector(startFresh), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Help & Info
        menu.addItem(NSMenuItem(title: "ℹ️ About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "☕ Support on Ko-Fi", action: #selector(openKoFi), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🚪 Quit", action: #selector(quit), keyEquivalent: ""))
        
        statusItem.menu = menu
    }
    
    // MARK: - Menu Bar Title Update
    private func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }
        
        if let activityInfo = activityTracker.getCurrentActivityInfo() {
            // Show activity name and duration alongside icon
            let pauseIndicator = activityTracker.isInBreak ? " ⏸️" : ""
            button.title = " \(activityInfo.activity)\(pauseIndicator) (\(activityInfo.timeString))"
        } else {
            // No active activity - just show icon
            button.title = ""
        }
    }
    
    private func startMenuBarUpdateTimer() {
        // Update menu bar title and menu items every 30 seconds to keep duration current
        menuBarUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.updateMenuBarTitle()
            self.updateMenuItems()
        }
    }
    
    private func startIconVisibilityCheckTimer() {
        // Check icon visibility every 5 seconds to ensure it hasn't disappeared
        iconVisibilityCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.ensureMenuBarIconVisible()
        }
        print("👀 Started icon visibility check timer (5 second interval)")
    }
    
    // MARK: - Icon Visibility Check
    private func ensureMenuBarIconVisible() {
        // Check if statusItem or its button has become nil
        if statusItem == nil {
            print("🚨 CRITICAL: statusItem is nil, recreating!")
            setupMenuBar()
            return
        }
        
        guard let button = statusItem.button else {
            print("🚨 WARNING: statusItem.button is nil, attempting to restore icon")
            updateStatusIcon()
            return
        }
        
        // Verify the icon is still set
        if button.image == nil {
            print("⚠️ WARNING: Menu bar icon image is missing, restoring it")
            updateStatusIcon()
        }
        
        // Optional: Log successful check (can be removed if too verbose)
        // print("✅ Icon visibility check passed")
    }
    
    // MARK: - Menu Items Update
    private func updateMenuItems() {
        // Update the current activity time display in menu items
        if let activityInfo = activityTracker.getCurrentActivityInfo(),
           let currentActivityMenuItem = currentActivityMenuItem,
           let currentTimeMenuItem = currentTimeMenuItem {
            let pauseIndicator = activityTracker.isInBreak ? " ⏸️" : ""
            currentActivityMenuItem.title = "🎯 Current: \(activityInfo.activity)\(pauseIndicator)"
            currentTimeMenuItem.title = "⏱️ Time: \(activityInfo.timeString)"
        }
    }
    
    // MARK: - Notification Observers
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(templatesUpdated),
            name: NSNotification.Name("TemplatesUpdated"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activityStateChanged),
            name: NSNotification.Name("ActivityStateChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showNewActivityDialogFromIdle),
            name: NSNotification.Name("ShowNewActivityDialog"),
            object: nil
        )
        
    }
    
    @objc private func templatesUpdated() {
        print("📢 Templates updated notification received")
        rebuildMenu()
    }
    
    @objc private func activityStateChanged() {
        print("📢 Activity state changed notification received")
        rebuildMenu()
        updateMenuBarTitle()
        updateMenuItems()
    }
    
    @objc private func showNewActivityDialogFromIdle() {
        // Triggered from idle return dialog when user chooses "Start New Activity"
        showEnhancedActivityDialog()
    }
    
    
    // MARK: - Global Keyboard Shortcuts
    private func setupGlobalKeyboardShortcuts() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 0 {
                DispatchQueue.main.async {
                    self.newActivity()
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    @objc private func quickStartActivity(_ sender: NSMenuItem) {
        guard let activityName = sender.representedObject as? String else { return }
        activityTracker.quickStartActivity(name: activityName)
    }
    
    // MARK: - Activity Management
    @objc private func newActivity() {
        showEnhancedActivityDialog()
    }
    
    private func showEnhancedActivityDialog() {
        let alert = NSAlert()
        alert.messageText = "🎯 Start New Activity"
        alert.informativeText = "Choose an option below:"
        
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 160))
        
        // Recent Activities popup button
        let recentLabel = NSTextField(labelWithString: "📈 Recent Activities:")
        recentLabel.font = NSFont.boldSystemFont(ofSize: 11)
        recentLabel.frame = NSRect(x: 20, y: 130, width: 120, height: 16)
        containerView.addSubview(recentLabel)
        
        let recentPopup = NSPopUpButton(frame: NSRect(x: 20, y: 105, width: 320, height: 25))
        recentPopup.addItem(withTitle: "Select recent activity...")
        recentPopup.menu?.addItem(NSMenuItem.separator())
        
        let recentActivities = activityTracker.getRecentActivities(limit: 8)
        for activity in recentActivities {
            recentPopup.addItem(withTitle: "⏮️ \(activity)")
        }
        
        if recentActivities.isEmpty {
            recentPopup.isEnabled = false
            recentPopup.menu?.item(at: 0)?.title = "No recent activities"
        }
        
        recentPopup.tag = 1001  // Tag for identification
        containerView.addSubview(recentPopup)
        
        // Templates popup button
        let templatesLabel = NSTextField(labelWithString: "🏷️ Activity Templates:")
        templatesLabel.font = NSFont.boldSystemFont(ofSize: 11)
        templatesLabel.frame = NSRect(x: 20, y: 75, width: 120, height: 16)
        containerView.addSubview(templatesLabel)
        
        let templatesPopup = NSPopUpButton(frame: NSRect(x: 20, y: 50, width: 320, height: 25))
        templatesPopup.addItem(withTitle: "Select template...")
        templatesPopup.menu?.addItem(NSMenuItem.separator())
        
        for template in preferences.activityTemplates {
            templatesPopup.addItem(withTitle: "\(template.emoji) \(template.name)")
        }
        
        if preferences.activityTemplates.isEmpty {
            templatesPopup.isEnabled = false
            templatesPopup.menu?.item(at: 0)?.title = "No templates (create in preferences)"
        }
        
        templatesPopup.tag = 1002  // Tag for identification
        containerView.addSubview(templatesPopup)
        
        // Custom activity input
        let customLabel = NSTextField(labelWithString: "✏️ Or enter custom activity:")
        customLabel.font = NSFont.boldSystemFont(ofSize: 11)
        customLabel.frame = NSRect(x: 20, y: 20, width: 160, height: 16)
        containerView.addSubview(customLabel)
        
        let customField = NSTextField(frame: NSRect(x: 20, y: 0, width: 320, height: 22))
        customField.placeholderString = "Type activity name..."
        customField.font = NSFont.systemFont(ofSize: 13)
        containerView.addSubview(customField)
        
        alert.accessoryView = containerView
        alert.addButton(withTitle: "Start Activity")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            var activityName: String? = nil
            
            // Check custom field first
            let customActivity = customField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !customActivity.isEmpty {
                activityName = customActivity
            }
            // Check recent activities popup
            else if recentPopup.indexOfSelectedItem > 1 {  // Skip "Select..." and separator
                let selectedTitle = recentPopup.selectedItem?.title ?? ""
                activityName = selectedTitle.replacingOccurrences(of: "⏮️ ", with: "")
            }
            // Check templates popup
            else if templatesPopup.indexOfSelectedItem > 1 {  // Skip "Select..." and separator
                let selectedIndex = templatesPopup.indexOfSelectedItem - 2  // Account for header and separator
                if selectedIndex >= 0 && selectedIndex < preferences.activityTemplates.count {
                    activityName = preferences.activityTemplates[selectedIndex].name
                }
            }
            
            if let name = activityName, !name.isEmpty {
                activityTracker.startActivity(name: name)
            } else {
                // Show error if nothing was selected
                let errorAlert = NSAlert()
                errorAlert.messageText = "No Activity Selected"
                errorAlert.informativeText = "Please select an activity or enter a custom name."
                errorAlert.alertStyle = .warning
                errorAlert.runModal()
            }
        }
    }
    
    
    @objc private func pauseResumeActivity() {
        activityTracker.pauseResumeActivity()
    }
    
    @objc private func endActivity() {
        activityTracker.endCurrentActivity()
    }
    
    @objc private func endDay() {
        activityTracker.endDay()
    }
    
    @objc private func startFresh() {
        activityTracker.startFresh()
    }
    
    
    
    
    // MARK: - Analytics & Reports
    @objc private func showDashboard() {
        analytics.showDashboard()
    }
    
    @objc private func generateReport() {
        analytics.generateReport()
    }
    
    @objc private func exportData() {
        analytics.showExportDialog()
    }
    
    // MARK: - Tools
    @objc private func manageTemplates() {
        templateManager.showManageTemplates()
    }
    
    
    @objc private func showPreferences() {
        let alert = NSAlert()
        alert.messageText = "⚙️ TimeDeck Preferences"
        alert.informativeText = "Customize your experience:"
        
        let prefView = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 280))
        
        // Notification status (simplified - no management needed for unsigned app)
        let notificationLabel = NSTextField(labelWithString: "📢 Notifications: Disabled (unsigned app)")
        notificationLabel.font = NSFont.systemFont(ofSize: 11)
        notificationLabel.textColor = .secondaryLabelColor
        notificationLabel.frame = NSRect(x: 20, y: 250, width: 300, height: 20)
        
        // Idle Detection section
        let idleLabel = NSTextField(labelWithString: "💤 Idle Detection")
        idleLabel.font = NSFont.boldSystemFont(ofSize: 12)
        idleLabel.frame = NSRect(x: 20, y: 190, width: 120, height: 20)
        
        let idleCheckbox = NSButton(checkboxWithTitle: "Enable idle detection", target: self, action: #selector(idleDetectionToggled(_:)))
        idleCheckbox.frame = NSRect(x: 20, y: 165, width: 200, height: 20)
        idleCheckbox.state = preferences.idleDetectionEnabled ? .on : .off
        
        // Idle timeout setting
        let idleTimeoutLabel = NSTextField(labelWithString: "Idle timeout (minutes):")
        idleTimeoutLabel.frame = NSRect(x: 20, y: 140, width: 150, height: 20)
        let idleTimeoutField = NSTextField(frame: NSRect(x: 180, y: 140, width: 60, height: 20))
        idleTimeoutField.integerValue = preferences.idleTimeoutMinutes
        idleTimeoutField.tag = 1001  // Tag for identification
        
        // Auto-end timeout setting
        let autoEndLabel = NSTextField(labelWithString: "Auto-end timeout (minutes):")
        autoEndLabel.frame = NSRect(x: 20, y: 110, width: 150, height: 20)
        let autoEndField = NSTextField(frame: NSRect(x: 180, y: 110, width: 60, height: 20))
        autoEndField.integerValue = preferences.autoEndTimeoutMinutes
        autoEndField.tag = 1002  // Tag for identification
        
        // Help text
        let helpLabel = NSTextField(labelWithString: """
        Idle timeout: How long before showing return dialog
        Auto-end timeout: How long to wait before auto-ending activity
        """)
        helpLabel.frame = NSRect(x: 20, y: 50, width: 360, height: 40)
        helpLabel.font = NSFont.systemFont(ofSize: 11)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.isEditable = false
        helpLabel.isBordered = false
        helpLabel.backgroundColor = .clear
        
        prefView.addSubview(notificationLabel)
        prefView.addSubview(idleLabel)
        prefView.addSubview(idleCheckbox)
        prefView.addSubview(idleTimeoutLabel)
        prefView.addSubview(idleTimeoutField)
        prefView.addSubview(autoEndLabel)
        prefView.addSubview(autoEndField)
        prefView.addSubview(helpLabel)
        
        alert.accessoryView = prefView
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Save the timeout values
            if let idleField = prefView.viewWithTag(1001) as? NSTextField {
                let idleTimeout = max(1, idleField.integerValue)  // Minimum 1 minute
                preferences.idleTimeoutMinutes = idleTimeout
            }
            
            if let autoEndField = prefView.viewWithTag(1002) as? NSTextField {
                let autoEndTimeout = max(5, autoEndField.integerValue)  // Minimum 5 minutes
                preferences.autoEndTimeoutMinutes = autoEndTimeout
            }
            
            notificationManager.showNotification(title: "⚙️ Preferences", message: "Settings saved successfully")
        }
    }
    
    @objc private func idleDetectionToggled(_ sender: NSButton) {
        preferences.idleDetectionEnabled = (sender.state == .on)
        if preferences.idleDetectionEnabled {
            activityTracker.startIdleDetection()
        } else {
            activityTracker.stopIdleDetection()
        }
    }
    
    
    // MARK: - Help & Info
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "🎯 TimeDeck v0.0.4"
        alert.informativeText = """
        Your friendly menu bar activity tracker! 🚀
        
        ✨ What it does:
        • Tracks what you're working on
        • Shows you where your time goes
        • Exports data for timesheets
        • Lives quietly in your menu bar
        
        📊 Three ways to wrap up:
        • End Activity - Stop current task
        • End Day - Stop + get daily summary
        • Start Fresh - Clear everything (careful!)
        
        Made with ☕ and lots of ⏰ tracking
        
        💙 Like TimeDeck? Buy me a coffee!
        ko-fi.com/joomux
        """
        
        alert.addButton(withTitle: "☕ Support")
        alert.addButton(withTitle: "Got it! 👍")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open Ko-fi link
            if let url = URL(string: "https://ko-fi.com/joomux") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @objc private func openKoFi() {
        if let url = URL(string: "https://ko-fi.com/joomux") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func installStreamDeckScripts() {
        // Get the app's Resources/StreamDeck directory
        guard let appPath = Bundle.main.resourcePath else {
            AlertManager.shared.showAlert(
                type: .error,
                title: "❌ Installation Failed",
                message: "Could not locate app resources.",
                primaryButton: "OK"
            )
            return
        }
        
        let bundledScriptsPath = "\(appPath)/StreamDeck"
        let fileManager = FileManager.default
        
        // Check if bundled scripts exist
        guard fileManager.fileExists(atPath: bundledScriptsPath) else {
            AlertManager.shared.showAlert(
                type: .error,
                title: "❌ Installation Failed", 
                message: "StreamDeck scripts not found in app bundle. Please contact support.",
                primaryButton: "OK"
            )
            return
        }
        
        // Create user's StreamDeck scripts directory
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let userScriptsPath = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("TimeDeck")
            .appendingPathComponent("StreamDeck")
        
        do {
            // Create directory if it doesn't exist
            try fileManager.createDirectory(at: userScriptsPath, withIntermediateDirectories: true, attributes: nil)
            
            // Get list of script files
            let scriptFiles = try fileManager.contentsOfDirectory(atPath: bundledScriptsPath)
            let shellScripts = scriptFiles.filter { $0.hasSuffix(".sh") }
            
            if shellScripts.isEmpty {
                AlertManager.shared.showAlert(
                    type: .warning,
                    title: "⚠️ No Scripts Found",
                    message: "No shell scripts found in app bundle.",
                    primaryButton: "OK"
                )
                return
            }
            
            // Copy each script
            var copiedScripts: [String] = []
            for script in shellScripts {
                let sourcePath = "\(bundledScriptsPath)/\(script)"
                let destinationPath = userScriptsPath.appendingPathComponent(script)
                
                // Remove existing file if it exists
                if fileManager.fileExists(atPath: destinationPath.path) {
                    try fileManager.removeItem(at: destinationPath)
                }
                
                // Copy the script
                try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath.path)
                
                // Make it executable
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationPath.path)
                
                copiedScripts.append(script)
            }
            
            // Show success message
            let scriptsPath = userScriptsPath.path.replacingOccurrences(of: fileManager.homeDirectoryForCurrentUser.path, with: "~")
            
            let response = AlertManager.shared.showAlert(
                type: .success,
                title: "✅ StreamDeck Scripts Installed",
                message: """
                Successfully installed \(copiedScripts.count) StreamDeck scripts to:
                
                \(scriptsPath)
                
                Scripts installed:
                • \(copiedScripts.joined(separator: "\n• "))
                
                You can now use these scripts in StreamDeck with the "System > Open" action.
                """,
                primaryButton: "Open Folder",
                secondaryButton: "Done"
            )
            
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(userScriptsPath)
            }
            
        } catch {
            AlertManager.shared.showAlert(
                type: .error,
                title: "❌ Installation Failed",
                message: "Failed to install StreamDeck scripts: \(error.localizedDescription)",
                primaryButton: "OK"
            )
        }
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main Entry Point moved to main.swift
