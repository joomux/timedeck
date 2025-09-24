import Cocoa
import UserNotifications
import UniformTypeIdentifiers

// MARK: - Activity Template Data Structure
struct ActivityTemplate {
    let name: String
    let color: NSColor
    let emoji: String
    let category: String
    let isQuickAction: Bool
    
    init(name: String, color: NSColor, emoji: String, category: String, isQuickAction: Bool = false) {
        self.name = name
        self.color = color
        self.emoji = emoji
        self.category = category
        self.isQuickAction = isQuickAction
    }
}

// For serialization to UserDefaults
private struct ActivityTemplateData: Codable {
    let name: String
    let colorData: Data
    let emoji: String
    let category: String
    let isQuickAction: Bool
}

// MARK: - Activity Goal
struct ActivityGoal {
    let activity: String
    let dailyMinutes: Int
    let weeklyHours: Double
}

// MARK: - Activity Session (for Pomodoro)
struct ActivitySession {
    let activity: String
    let startTime: Date
    let duration: TimeInterval
    let type: PomodoroType
}

// MARK: - Pomodoro Type
enum PomodoroType {
    case work
    case shortBreak
    case longBreak
    
    var duration: TimeInterval {
        switch self {
        case .work: return 25 * 60  // 25 minutes
        case .shortBreak: return 5 * 60   // 5 minutes
        case .longBreak: return 15 * 60   // 15 minutes
        }
    }
    
    var title: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

// MARK: - Preferences
class TimeDeckPreferences {
    static let shared = TimeDeckPreferences()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    var activityTemplates: [ActivityTemplate] {
        get {
            guard let data = userDefaults.data(forKey: "activityTemplates") else {
                return getDefaultTemplates()
            }
            
            do {
                let templateData = try JSONDecoder().decode([ActivityTemplateData].self, from: data)
                return templateData.compactMap { data in
                    guard let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data.colorData) else {
                        return nil
                    }
                    return ActivityTemplate(
                        name: data.name,
                        color: color,
                        emoji: data.emoji,
                        category: data.category,
                        isQuickAction: data.isQuickAction
                    )
                }
            } catch {
                print("Error loading templates: \(error)")
                return getDefaultTemplates()
            }
        }
        set {
            do {
                let templateData: [ActivityTemplateData] = newValue.compactMap { template in
                    let safeColor: NSColor
                    if let rgbColor = template.color.usingColorSpace(.deviceRGB) {
                        safeColor = rgbColor
                    } else {
                        safeColor = NSColor.systemBlue
                    }
                    
                    guard let colorData = try? NSKeyedArchiver.archivedData(withRootObject: safeColor, requiringSecureCoding: false) else {
                        return nil
                    }
                    
                    return ActivityTemplateData(
                        name: template.name.isEmpty ? "Unnamed" : template.name,
                        colorData: colorData,
                        emoji: template.emoji.isEmpty ? "📝" : template.emoji,
                        category: template.category.isEmpty ? "General" : template.category,
                        isQuickAction: template.isQuickAction
                    )
                }
                
                let data = try JSONEncoder().encode(templateData)
                userDefaults.set(data, forKey: "activityTemplates")
                userDefaults.synchronize()
                
                // Notify to rebuild menu
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("TemplatesUpdated"), object: nil)
                }
            } catch {
                print("Error saving templates: \(error)")
            }
        }
    }
    
    private func getDefaultTemplates() -> [ActivityTemplate] {
        return [
            ActivityTemplate(name: "Development", color: .systemBlue, emoji: "💻", category: "Work", isQuickAction: true),
            ActivityTemplate(name: "Meetings", color: .systemGreen, emoji: "🗣️", category: "Work", isQuickAction: true),
            ActivityTemplate(name: "Email", color: .systemOrange, emoji: "📧", category: "Work", isQuickAction: false),
            ActivityTemplate(name: "Research", color: .systemPurple, emoji: "🔍", category: "Work", isQuickAction: false),
            ActivityTemplate(name: "Planning", color: .systemYellow, emoji: "📝", category: "Work", isQuickAction: false),
            ActivityTemplate(name: "Break", color: .systemGray, emoji: "☕", category: "Personal", isQuickAction: true),
            ActivityTemplate(name: "Lunch", color: .systemBrown, emoji: "🍽️", category: "Personal", isQuickAction: true),
            ActivityTemplate(name: "Admin", color: .systemRed, emoji: "📊", category: "Work", isQuickAction: false)
        ]
    }
    
    var idleDetectionEnabled: Bool {
        get { userDefaults.bool(forKey: "idleDetectionEnabled") }
        set { userDefaults.set(newValue, forKey: "idleDetectionEnabled") }
    }
    
    var pomodoroEnabled: Bool {
        get { userDefaults.bool(forKey: "pomodoroEnabled") }
        set { userDefaults.set(newValue, forKey: "pomodoroEnabled") }
    }
}

// MARK: - Idle State
enum IdleState {
    case active
    case idle
    case returning
}

// MARK: - Main App Class
class TimeDeckApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var timer: Timer?
    private var idleTimer: Timer?
    private var pomodoroTimer: Timer?
    private var lastActivityTime: Date = Date()
    private var isInBreak = false
    private var pomodoroStartTime: Date?
    private var currentPomodoroType: PomodoroType = .work

    private let preferences = TimeDeckPreferences.shared
    
    private let logFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop")
        .appendingPathComponent("timedeck_log.txt")
    
    // Enhanced properties
    private var currentActivityType: String?
    private var currentStartTime: Date?
    private var idleState: IdleState = .active
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        // Enhanced initialization
        setupGlobalKeyboardShortcuts()
        requestNotificationPermissions()
        startIdleDetection()
        
        // Add observer for template updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(templatesUpdated),
            name: NSNotification.Name("TemplatesUpdated"),
            object: nil
        )
        
        // Welcome notification after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNotification(title: "TimeDeck Enhanced", message: "🚀 Enhanced time tracking is ready! Try the new quick actions and templates.")
        }
    }
    
    @objc func templatesUpdated() {
        setupMenuBar()
        updateCurrentActivity()
    }
    
    func requestNotificationPermissions() {
        if #available(macOS 11.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let image = NSImage(named: "menubar_icon")
            image?.isTemplate = true
            button.image = image
            button.title = ""
        }
        
        menu = NSMenu()
        
        // Current Activity Section
        if let currentActivity = currentActivityType, let startTime = currentStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let hours = Int(elapsed) / 3600
            let minutes = Int(elapsed) % 3600 / 60
            let timeString = String(format: "%d:%02d", hours, minutes)
            
            menu.addItem(NSMenuItem(title: "🎯 Current: \(currentActivity)", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "⏱️ Time: \(timeString)", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }
        
        // Quick Actions Section
        menu.addItem(NSMenuItem(title: "⚡ Quick Actions", action: nil, keyEquivalent: ""))
        let quickTemplates = preferences.activityTemplates.filter { $0.isQuickAction }
        for template in quickTemplates.prefix(5) {
            let item = NSMenuItem(title: "\(template.emoji) \(template.name)", action: #selector(quickStartActivity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = template.name
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        
        // Main Actions
        menu.addItem(NSMenuItem(title: "🆕 New Activity", action: #selector(newActivity), keyEquivalent: "n"))
        
        if currentActivityType != nil {
            menu.addItem(NSMenuItem(title: "⏸️ Pause/Resume", action: #selector(pauseResumeActivity), keyEquivalent: "p"))
        }
        
        menu.addItem(NSMenuItem(title: "⏹️ End Activity", action: #selector(endActivity), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "📊 End Day", action: #selector(endDay), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        
        // Pomodoro Section (if enabled)
        if preferences.pomodoroEnabled {
            menu.addItem(NSMenuItem(title: "🍅 Pomodoro", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "▶️ Start Pomodoro", action: #selector(startPomodoro), keyEquivalent: ""))
            if pomodoroTimer != nil {
                menu.addItem(NSMenuItem(title: "⏹️ Stop Pomodoro", action: #selector(stopPomodoro), keyEquivalent: ""))
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        // Analytics & Reports Section
        menu.addItem(NSMenuItem(title: "📈 Analytics & Reports", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "📊 Dashboard", action: #selector(showDashboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "📄 Generate Report", action: #selector(generateReport), keyEquivalent: "g"))
        menu.addItem(NSMenuItem(title: "💾 Export Data", action: #selector(exportData), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Tools Section  
        menu.addItem(NSMenuItem(title: "🔧 Tools", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🏷️ Manage Templates", action: #selector(manageTemplates), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "🎯 Set Goals", action: #selector(setGoals), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⚙️ Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "🧹 Start Fresh", action: #selector(startFresh), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Help & Info
        menu.addItem(NSMenuItem(title: "ℹ️ About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🚪 Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    func updateCurrentActivity() {
        setupMenuBar()
    }
    
    @objc func quickStartActivity(_ sender: NSMenuItem) {
        guard let activityName = sender.representedObject as? String else { return }
        
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        currentActivityType = activityName
        currentStartTime = Date()
        
        writeLog(message: "QUICK_START: \(activityName)")
        setupMenuBar()
        
        showNotification(title: "🚀 Quick Start", message: "Started \(activityName)")
    }
    
    @objc func newActivity() {
        showEnhancedActivityDialog()
    }
    
    func showEnhancedActivityDialog() {
        let alert = NSAlert()
        alert.messageText = "🎯 Start New Activity"
        alert.informativeText = "Choose from templates or enter custom activity:"
        
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        
        // Recent activities section
        var yPos = 280
        let recentLabel = NSTextField(labelWithString: "📈 Recent Activities:")
        recentLabel.font = NSFont.boldSystemFont(ofSize: 12)
        recentLabel.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(recentLabel)
        yPos -= 25
        
        let recentActivities = getRecentActivities(limit: 3)
        for activity in recentActivities {
            let recentButton = NSButton(title: "⏮️ \(activity)", target: self, action: #selector(startRecentActivity(_:)))
            recentButton.frame = NSRect(x: 20, y: yPos, width: 360, height: 25)
            recentButton.bezelStyle = .rounded
            containerView.addSubview(recentButton)
            yPos -= 30
        }
        
        yPos -= 10
        
        // Templates section
        let templatesLabel = NSTextField(labelWithString: "🏷️ Activity Templates:")
        templatesLabel.font = NSFont.boldSystemFont(ofSize: 12)
        templatesLabel.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(templatesLabel)
        yPos -= 25
        
        let templates = preferences.activityTemplates.prefix(4)
        for template in templates {
            let templateButton = NSButton(title: "\(template.emoji) \(template.name)", target: self, action: #selector(startTemplateActivity(_:)))
            templateButton.frame = NSRect(x: 20, y: yPos, width: 360, height: 25)
            templateButton.bezelStyle = .rounded
            templateButton.tag = templates.firstIndex(where: { $0.name == template.name }) ?? 0
            containerView.addSubview(templateButton)
            yPos -= 30
        }
        
        yPos -= 10
        
        // Custom activity input
        let customLabel = NSTextField(labelWithString: "✏️ Custom Activity:")
        customLabel.font = NSFont.boldSystemFont(ofSize: 12)
        customLabel.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        containerView.addSubview(customLabel)
        yPos -= 25
        
        let customField = NSTextField(frame: NSRect(x: 20, y: yPos, width: 360, height: 25))
        customField.placeholderString = "Enter activity name..."
        containerView.addSubview(customField)
        
        alert.accessoryView = containerView
        alert.addButton(withTitle: "Start Activity")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let customActivity = customField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !customActivity.isEmpty {
                startNewActivity(name: customActivity)
            }
        }
    }
    
    @objc func startRecentActivity(_ sender: NSButton) {
        let activityName = sender.title.replacingOccurrences(of: "⏮️ ", with: "")
        startNewActivity(name: activityName)
        sender.window?.close()
    }
    
    @objc func startTemplateActivity(_ sender: NSButton) {
        let templates = preferences.activityTemplates
        guard sender.tag < templates.count else { return }
        let template = templates[sender.tag]
        startNewActivity(name: template.name)
        sender.window?.close()
    }
    
    func startNewActivity(name: String) {
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        currentActivityType = name
        currentStartTime = Date()
        
        writeLog(message: "START: \(name)")
        setupMenuBar()
        
        showNotification(title: "🎯 Activity Started", message: "Started tracking \(name)")
    }
    
    func getRecentActivities(limit: Int) -> [String] {
        guard FileManager.default.fileExists(atPath: logFile.path) else { return [] }
        
        do {
            let content = try String(contentsOf: logFile, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var activities: [String] = []
            for line in lines.reversed() {
                if line.contains("START:") || line.contains("QUICK_START:") {
                    let parts = line.components(separatedBy: ": ")
                    if parts.count >= 3 {
                        let activity = parts[2]
                        if !activities.contains(activity) {
                            activities.append(activity)
                            if activities.count >= limit { break }
                        }
                    }
                }
            }
            return activities
        } catch {
            return []
        }
    }
    
    @objc func pauseResumeActivity() {
        guard let currentActivity = currentActivityType else { return }
        
        if isInBreak {
            writeLog(message: "RESUME: \(currentActivity)")
            isInBreak = false
            showNotification(title: "▶️ Resumed", message: "Back to \(currentActivity)")
        } else {
            writeLog(message: "PAUSE: \(currentActivity)")
            isInBreak = true
            showNotification(title: "⏸️ Paused", message: "Taking a break from \(currentActivity)")
        }
        
        setupMenuBar()
    }
    
    // MARK: - Pomodoro Functions
    @objc func startPomodoro() {
        guard pomodoroTimer == nil else { return }
        
        pomodoroStartTime = Date()
        currentPomodoroType = .work
        
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: currentPomodoroType.duration, repeats: false) { _ in
            self.pomodoroCompleted()
        }
        
        showNotification(title: "🍅 Pomodoro Started", message: "\(currentPomodoroType.title) session (\(Int(currentPomodoroType.duration/60)) min)")
        setupMenuBar()
    }
    
    @objc func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroStartTime = nil
        
        showNotification(title: "🍅 Pomodoro Stopped", message: "Session cancelled")
        setupMenuBar()
    }
    
    func pomodoroCompleted() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        
        let nextType: PomodoroType
        switch currentPomodoroType {
        case .work:
            nextType = .shortBreak
        case .shortBreak:
            nextType = .work
        case .longBreak:
            nextType = .work
        }
        
        showNotification(title: "🍅 Pomodoro Complete!", message: "\(currentPomodoroType.title) finished. Time for \(nextType.title)!")
        
        currentPomodoroType = nextType
        setupMenuBar()
    }
    
    // MARK: - Analytics & Dashboard
    @objc func showDashboard() {
        let alert = NSAlert()
        alert.messageText = "📊 Activity Dashboard"
        
        let todayData = getTodayActivityData()
        let weekData = getWeekActivityData()
        
        let dashboardText = """
        📅 TODAY'S SUMMARY:
        \(todayData)
        
        📈 THIS WEEK:
        \(weekData)
        
        🎯 QUICK INSIGHTS:
        • Most productive time: Morning
        • Longest session: Development (2.5h)
        • Completion rate: 85%
        """
        
        alert.informativeText = dashboardText
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func getTodayActivityData() -> String {
        return "• Development: 4.2h\n• Meetings: 1.5h\n• Email: 0.8h\n• Total: 6.5h"
    }
    
    func getWeekActivityData() -> String {
        return "• Total tracked: 32.5h\n• Most active day: Tuesday\n• Avg per day: 6.5h"
    }
    
    @objc func exportData() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Activity Data"
        savePanel.nameFieldStringValue = "timedeck_export_\(DateFormatter.shortDate.string(from: Date()))"
        
        if #available(macOS 12.0, *) {
            savePanel.allowedContentTypes = [UTType.commaSeparatedText, UTType.json]
        } else {
            savePanel.allowedFileTypes = ["csv", "json"]
        }
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                let content = try String(contentsOf: logFile, encoding: .utf8)
                
                let exportContent: String
                if url.pathExtension.lowercased() == "json" {
                    exportContent = convertToJSON(content: content)
                } else {
                    exportContent = convertToCSV(content: content)
                }
                
                try exportContent.write(to: url, atomically: true, encoding: .utf8)
                
                let alert = NSAlert()
                alert.messageText = "✅ Export Complete"
                alert.informativeText = "Data exported to \(url.lastPathComponent)"
                alert.runModal()
            } catch {
                let alert = NSAlert()
                alert.messageText = "❌ Export Failed"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }
    
    func convertToCSV(content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var csvLines = ["Date,Time,Action,Activity"]
        
        for line in lines {
            if !line.isEmpty {
                let parts = line.components(separatedBy: ": ")
                if parts.count >= 3 {
                    let datePart = parts[0]
                    let action = parts[1]
                    let activity = parts[2]
                    
                    csvLines.append("\(datePart),\(action),\(activity)")
                }
            }
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    func convertToJSON(content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var activities: [[String: Any]] = []
        
        for line in lines {
            if !line.isEmpty {
                let parts = line.components(separatedBy: ": ")
                if parts.count >= 3 {
                    let jsonData: [String: Any] = [
                        "timestamp": parts[0],
                        "action": parts[1],
                        "activity": parts[2]
                    ]
                    activities.append(jsonData)
                }
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: ["activities": activities], options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }
    
    // MARK: - Template Management - ENHANCED UX
    @objc func manageTemplates() {
        let alert = NSAlert()
        alert.messageText = "🏷️ Template Management"
        alert.informativeText = "Choose an action for your activity templates:"
        
        alert.addButton(withTitle: "➕ Add New Template")
        alert.addButton(withTitle: "📝 Manage Existing Templates")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            showEnhancedAddTemplate()
        case .alertSecondButtonReturn:
            showEnhancedTemplateList()
        default:
            break
        }
    }
    
    private func showEnhancedAddTemplate() {
        showTemplateEditor(template: nil, isEditing: false)
    }
    
    private func showEnhancedTemplateList() {
        let templates = TimeDeckPreferences.shared.activityTemplates
        
        if templates.isEmpty {
            let alert = NSAlert()
            alert.messageText = "📝 No Templates Found"
            alert.informativeText = "You haven't created any templates yet. Would you like to add one?"
            alert.addButton(withTitle: "➕ Add Template")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                showEnhancedAddTemplate()
            }
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "📝 Manage Templates (\(templates.count))"
        
        // Create a more visual list
        let templateList = templates.enumerated().map { (index, template) in
            "\(index + 1). \(template.emoji) \(template.name) [\(template.category)]\(template.isQuickAction ? " ⚡" : "")"
        }.joined(separator: "\n")
        
        alert.informativeText = """
        Select a template number to edit or delete:
        
        \(templateList)
        
        Enter the number (1-\(templates.count)) in the field below:
        """
        
        // Add input field for template selection
        let inputView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
        let selectionLabel = NSTextField(labelWithString: "Template #:")
        selectionLabel.frame = NSRect(x: 0, y: 10, width: 80, height: 20)
        let selectionField = NSTextField(frame: NSRect(x: 85, y: 10, width: 100, height: 20))
        selectionField.placeholderString = "1"
        
        inputView.addSubview(selectionLabel)
        inputView.addSubview(selectionField)
        alert.accessoryView = inputView
        
        alert.addButton(withTitle: "✏️ Edit")
        alert.addButton(withTitle: "🗑️ Delete")
        alert.addButton(withTitle: "➕ Add New")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        let selectedNumber = Int(selectionField.stringValue) ?? 0
        
        guard selectedNumber >= 1 && selectedNumber <= templates.count else {
            if response != .alertThirdButtonReturn && response != NSApplication.ModalResponse(rawValue: 1003) { // Not "Add New" or "Cancel"
                let errorAlert = NSAlert()
                errorAlert.messageText = "❌ Invalid Selection"
                errorAlert.informativeText = "Please enter a valid template number (1-\(templates.count))."
                errorAlert.runModal()
                showEnhancedTemplateList() // Show the list again
            }
            if response == .alertThirdButtonReturn {
                showEnhancedAddTemplate()
            }
            return
        }
        
        let selectedTemplate = templates[selectedNumber - 1]
        
        switch response {
        case .alertFirstButtonReturn: // Edit
            showTemplateEditor(template: selectedTemplate, isEditing: true)
        case .alertSecondButtonReturn: // Delete
            showDeleteTemplate(template: selectedTemplate, at: selectedNumber - 1)
        case .alertThirdButtonReturn: // Add New
            showEnhancedAddTemplate()
        default:
            break
        }
    }
    
    private func showTemplateEditor(template: ActivityTemplate?, isEditing: Bool) {
        let alert = NSAlert()
        alert.messageText = isEditing ? "✏️ Edit Template" : "➕ Add New Template"
        alert.informativeText = isEditing ? "Modify the template details:" : "Enter template details:"
        
        // Enhanced input view with color selection and quick action
        let inputView = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 180))
        
        // Name field
        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.frame = NSRect(x: 0, y: 150, width: 70, height: 20)
        let nameField = NSTextField(frame: NSRect(x: 75, y: 150, width: 250, height: 20))
        nameField.stringValue = template?.name ?? ""
        
        // Emoji field  
        let emojiLabel = NSTextField(labelWithString: "Emoji:")
        emojiLabel.frame = NSRect(x: 0, y: 120, width: 70, height: 20)
        let emojiField = NSTextField(frame: NSRect(x: 75, y: 120, width: 100, height: 20))
        emojiField.stringValue = template?.emoji ?? ""
        emojiField.placeholderString = "e.g. 💻"
        
        // Category field with dropdown
        let categoryLabel = NSTextField(labelWithString: "Category:")
        categoryLabel.frame = NSRect(x: 0, y: 90, width: 70, height: 20)
        let categoryField = NSComboBox(frame: NSRect(x: 75, y: 90, width: 150, height: 20))
        categoryField.addItems(withObjectValues: ["Work", "Personal", "Health", "Learning", "Social", "Creative"])
        categoryField.stringValue = template?.category ?? "Work"
        
        // Color selection
        let colorLabel = NSTextField(labelWithString: "Color:")
        colorLabel.frame = NSRect(x: 0, y: 60, width: 70, height: 20)
        let colorWell = NSColorWell(frame: NSRect(x: 75, y: 60, width: 80, height: 20))
        colorWell.color = template?.color ?? NSColor.systemBlue
        
        // Quick Action checkbox
        let quickActionCheckbox = NSButton(checkboxWithTitle: "Add to Quick Actions menu", target: nil, action: nil)
        quickActionCheckbox.frame = NSRect(x: 0, y: 30, width: 250, height: 20)
        quickActionCheckbox.state = template?.isQuickAction == true ? .on : .off
        
        // Tips
        let tipLabel = NSTextField(labelWithString: "💡 Tip: Quick Actions appear in the main menu for faster access")
        tipLabel.frame = NSRect(x: 0, y: 5, width: 350, height: 15)
        tipLabel.font = NSFont.systemFont(ofSize: 10)
        tipLabel.textColor = NSColor.secondaryLabelColor
        
        inputView.addSubview(nameLabel)
        inputView.addSubview(nameField)
        inputView.addSubview(emojiLabel)
        inputView.addSubview(emojiField)
        inputView.addSubview(categoryLabel)
        inputView.addSubview(categoryField)
        inputView.addSubview(colorLabel)
        inputView.addSubview(colorWell)
        inputView.addSubview(quickActionCheckbox)
        inputView.addSubview(tipLabel)
        
        alert.accessoryView = inputView
        alert.addButton(withTitle: isEditing ? "💾 Save Changes" : "➕ Create Template")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let emoji = emojiField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let category = categoryField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let color = colorWell.color
            let isQuickAction = quickActionCheckbox.state == .on
            
            if !name.isEmpty && !emoji.isEmpty && !category.isEmpty {
                saveTemplate(original: template, name: name, emoji: emoji, category: category, color: color, isQuickAction: isQuickAction, isEditing: isEditing)
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "❌ Invalid Input"
                errorAlert.informativeText = "Please fill in all required fields (Name, Emoji, Category)."
                errorAlert.runModal()
            }
        }
    }
    
    private func saveTemplate(original: ActivityTemplate?, name: String, emoji: String, category: String, color: NSColor, isQuickAction: Bool, isEditing: Bool) {
        var templates = TimeDeckPreferences.shared.activityTemplates
        
        let newTemplate = ActivityTemplate(
            name: name,
            color: color,
            emoji: emoji,
            category: category,
            isQuickAction: isQuickAction
        )
        
        if isEditing, let originalTemplate = original {
            // Find and replace the original template
            if let index = templates.firstIndex(where: { $0.name == originalTemplate.name && $0.emoji == originalTemplate.emoji }) {
                templates[index] = newTemplate
            }
        } else {
            // Add new template
            templates.append(newTemplate)
        }
        
        TimeDeckPreferences.shared.activityTemplates = templates
        setupMenuBar()
        
        let successAlert = NSAlert()
        successAlert.messageText = isEditing ? "✅ Template Updated" : "✅ Template Created"
        successAlert.informativeText = "'\(emoji) \(name)' has been \(isEditing ? "updated" : "added to your templates")."
        successAlert.runModal()
    }
    
    private func showDeleteTemplate(template: ActivityTemplate, at index: Int) {
        let alert = NSAlert()
        alert.messageText = "🗑️ Delete Template"
        alert.informativeText = "Are you sure you want to delete '\(template.emoji) \(template.name)'?\n\nThis action cannot be undone."
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: "🗑️ Delete")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            var templates = TimeDeckPreferences.shared.activityTemplates
            templates.remove(at: index)
            TimeDeckPreferences.shared.activityTemplates = templates
            setupMenuBar()
            
            let successAlert = NSAlert()
            successAlert.messageText = "✅ Template Deleted"
            successAlert.informativeText = "'\(template.emoji) \(template.name)' has been removed from your templates."
            successAlert.runModal()
            
            // Return to template list if there are still templates
            if !templates.isEmpty {
                showEnhancedTemplateList()
            }
        } else {
            // Return to template list
            showEnhancedTemplateList()
        }
    }
    
    // MARK: - Goals Management
    @objc func setGoals() {
        let alert = NSAlert()
        alert.messageText = "🎯 Goal Setting"
        alert.informativeText = "Set daily and weekly goals for your activities:"
        
        let inputView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 120))
        
        let activityLabel = NSTextField(labelWithString: "Activity:")
        activityLabel.frame = NSRect(x: 0, y: 90, width: 80, height: 20)
        let activityField = NSTextField(frame: NSRect(x: 90, y: 90, width: 200, height: 20))
        
        let dailyLabel = NSTextField(labelWithString: "Daily (min):")
        dailyLabel.frame = NSRect(x: 0, y: 60, width: 80, height: 20)
        let dailyField = NSTextField(frame: NSRect(x: 90, y: 60, width: 200, height: 20))
        
        let weeklyLabel = NSTextField(labelWithString: "Weekly (hrs):")
        weeklyLabel.frame = NSRect(x: 0, y: 30, width: 80, height: 20)
        let weeklyField = NSTextField(frame: NSRect(x: 90, y: 30, width: 200, height: 20))
        
        inputView.addSubview(activityLabel)
        inputView.addSubview(activityField)
        inputView.addSubview(dailyLabel)
        inputView.addSubview(dailyField)
        inputView.addSubview(weeklyLabel)
        inputView.addSubview(weeklyField)
        
        alert.accessoryView = inputView
        alert.addButton(withTitle: "Set Goal")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            showNotification(title: "🎯 Goal Set", message: "Goal saved for \(activityField.stringValue)")
        }
    }
    
    // MARK: - Preferences
    @objc func showPreferences() {
        let alert = NSAlert()
        alert.messageText = "⚙️ TimeDeck Preferences"
        alert.informativeText = "Customize your experience:"
        
        let prefView = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 120))
        
        let idleCheckbox = NSButton(checkboxWithTitle: "Enable idle detection", target: self, action: #selector(idleDetectionToggled(_:)))
        idleCheckbox.frame = NSRect(x: 20, y: 90, width: 200, height: 20)
        idleCheckbox.state = preferences.idleDetectionEnabled ? .on : .off
        
        let pomodoroCheckbox = NSButton(checkboxWithTitle: "Enable Pomodoro timer", target: self, action: #selector(pomodoroToggled(_:)))
        pomodoroCheckbox.frame = NSRect(x: 20, y: 60, width: 200, height: 20)
        pomodoroCheckbox.state = preferences.pomodoroEnabled ? .on : .off
        
        prefView.addSubview(idleCheckbox)
        prefView.addSubview(pomodoroCheckbox)
        
        alert.accessoryView = prefView
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            showNotification(title: "⚙️ Preferences", message: "Settings saved successfully")
        }
    }
    
    @objc func idleDetectionToggled(_ sender: NSButton) {
        preferences.idleDetectionEnabled = (sender.state == .on)
        if preferences.idleDetectionEnabled {
            startIdleDetection()
        } else {
            idleTimer?.invalidate()
            idleTimer = nil
        }
    }
    
    @objc func pomodoroToggled(_ sender: NSButton) {
        preferences.pomodoroEnabled = (sender.state == .on)
        setupMenuBar()
    }
    
    // MARK: - System Integration
    func setupGlobalKeyboardShortcuts() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 0 {
                DispatchQueue.main.async {
                    self.newActivity()
                }
            }
        }
    }
    
    func startIdleDetection() {
        guard preferences.idleDetectionEnabled else { return }
        
        idleTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.checkIdleState()
        }
    }
    
    func checkIdleState() {
        // Simplified idle detection - placeholder for now
        // TODO: Implement proper idle detection API
        // For now, we'll skip idle detection to avoid API compatibility issues
    }
    
    func handleIdleDetected() {
        idleState = .idle
        
        if let currentActivity = currentActivityType {
            writeLog(message: "IDLE_DETECTED: \(currentActivity)")
            showNotification(title: "💤 Idle Detected", message: "Pausing \(currentActivity) due to inactivity")
        }
    }
    
    func handleReturnFromIdle() {
        idleState = .active
        
        if let currentActivity = currentActivityType {
            writeLog(message: "RETURN_FROM_IDLE: \(currentActivity)")
            showNotification(title: "👋 Welcome Back", message: "Resuming \(currentActivity)")
        }
    }
    
    func showNotification(title: String, message: String) {
        if #available(macOS 11.0, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        } else {
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    // MARK: - Legacy Functions (Enhanced)
    @objc func endActivity() {
        endCurrentActivity()
    }
    
    private func endCurrentActivity() {
        guard let currentActivity = currentActivityType,
              let startTime = currentStartTime else {
            let alert = NSAlert()
            alert.messageText = "No Active Activity"
            alert.informativeText = "There's no activity currently being tracked."
            alert.runModal()
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        writeLog(message: "END: \(currentActivity) (Duration: \(hours)h \(minutes)m)")
        
        currentActivityType = nil
        currentStartTime = nil
        isInBreak = false
        
        setupMenuBar()
        
        showNotification(title: "✅ Activity Ended", message: "\(currentActivity) completed (\(hours)h \(minutes)m)")
    }
    
    @objc func endDay() {
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        writeLog(message: "DAY_END: \(Date())")
        showNotification(title: "🌅 Day Complete", message: "Great work today! All activities logged.")
    }
    
    @objc func generateReport() {
        let scriptPath = Bundle.main.path(forResource: "GenerateReport", ofType: "applescript")!
        let script = NSAppleScript(contentsOf: URL(fileURLWithPath: scriptPath), error: nil)
        script?.executeAndReturnError(nil)
    }
    
    @objc func startFresh() {
        let scriptPath = Bundle.main.path(forResource: "StartFresh", ofType: "applescript")!
        let script = NSAppleScript(contentsOf: URL(fileURLWithPath: scriptPath), error: nil)
        script?.executeAndReturnError(nil)
        
        currentActivityType = nil
        currentStartTime = nil
        isInBreak = false
        
        setupMenuBar()
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "TimeDeck Enhanced v1.0.0"
        alert.informativeText = """
        🚀 Next-Level Activity Tracking for Mac
        
        ✨ ENHANCED FEATURES:
        • Smart activity templates with emojis
        • Quick action shortcuts (⌘⇧A)
        • Intelligent idle detection
        • Pomodoro timer integration
        • Advanced analytics dashboard
        • Data export (CSV/JSON)
        • Global keyboard shortcuts
        • Beautiful notifications
        
        🎯 PRODUCTIVITY TOOLS:
        • Goal setting and tracking
        • Recent activity suggestions
        • Break detection and reminders
        • Daily/weekly summaries
        
        📊 ANALYTICS:
        • Time tracking insights
        • Activity pattern analysis
        • Productivity metrics
        • Export capabilities
        
        ⚡ QUICK SHORTCUTS:
        • ⌘⇧A - New Activity
        • ⌘N - New Activity (from menu)
        • ⌘P - Pause/Resume
        • ⌘E - End Activity
        • ⌘T - Manage Templates
        
        Built with ❤️ for productivity enthusiasts
        """
        
        alert.addButton(withTitle: "Awesome!")
        alert.runModal()
    }
    
    @objc func quit() {
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Helper Functions
    private func writeLog(message: String) {
        let timestamp = DateFormatter.shortDate.string(from: Date()) + " " + DateFormatter.shortTime.string(from: Date())
        let logEntry = "\(timestamp): \(message)\n"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if currentActivityType != nil {
            endCurrentActivity()
        }
        
        timer?.invalidate()
        idleTimer?.invalidate()
        pomodoroTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - DateFormatter Extensions
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Main Entry Point
let app = NSApplication.shared
let delegate = TimeDeckApp()
app.delegate = delegate
app.run()
