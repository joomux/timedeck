import Cocoa
import Foundation

class TimeDeckApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var timer: Timer?
    private let logFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop")
        .appendingPathComponent("timedeck_log.txt")
    private let reportFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop") 
        .appendingPathComponent("timedeck_report.txt")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        updateCurrentActivity()
        
        // Update every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.updateCurrentActivity()
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Try to load the menu bar icon from the app bundle
        if let iconImage = loadMenuBarIcon() {
            statusItem.button?.image = iconImage
        } else {
            // Fallback to emoji if icon not found
            statusItem.button?.title = "📊"
        }
        
        menu = NSMenu()
        menu.autoenablesItems = false
        
        menu.addItem(NSMenuItem(title: "⚪ No active activity", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "New Activity", action: #selector(newActivity), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "End Activity", action: #selector(endActivity), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "End Day Summary", action: #selector(endDay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Generate Report", action: #selector(generateReport), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Start Fresh", action: #selector(startFresh), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Log File", action: #selector(openLogFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Report File", action: #selector(openReportFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        // Set target for all items except quit
        for item in menu.items {
            if item.title != "Quit" && item.isSeparatorItem == false {
                item.target = self
            }
        }
    }
    
    func updateCurrentActivity() {
        guard let currentActivityItem = menu.items.first else { return }
        
        do {
            if FileManager.default.fileExists(atPath: logFile.path) {
                let content = try String(contentsOf: logFile, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                
                if let lastLine = lines.last, !lastLine.hasSuffix("END") {
                    let components = lastLine.components(separatedBy: " ")
                    if components.count >= 2,
                       let timestamp = TimeInterval(components[0]) {
                        let activityName = components.dropFirst().joined(separator: " ")
                        let duration = Int(Date().timeIntervalSince1970 - timestamp)
                        let hours = duration / 3600
                        let minutes = (duration % 3600) / 60
                        
                        currentActivityItem.title = "🟢 \(activityName) (\(hours)h \(minutes)m)"
                        return
                    }
                }
            }
        } catch {
            print("Error reading log file: \(error)")
        }
        
        currentActivityItem.title = "⚪ No active activity"
    }
    
    @objc func newActivity() {
        let alert = NSAlert()
        alert.messageText = "New Activity"
        alert.informativeText = "Enter activity name:"
        alert.addButton(withTitle: "Start Activity")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "Activity name"
        alert.accessoryView = textField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn && !textField.stringValue.isEmpty {
            runAppleScript("NewActivity", args: [textField.stringValue])
            updateCurrentActivity()
        }
    }
    
    @objc func endActivity() {
        runAppleScript("EndActivity")
        updateCurrentActivity()
    }
    
    @objc func endDay() {
        runAppleScript("EndDay")
        updateCurrentActivity()
    }
    
    @objc func generateReport() {
        runAppleScript("GenerateReport")
    }
    
    @objc func startFresh() {
        let alert = NSAlert()
        alert.messageText = "Start Fresh"
        alert.informativeText = "This will clear all activity data. Are you sure?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes, Clear All Data")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            runAppleScript("StartFresh")
            updateCurrentActivity()
        }
    }
    
    @objc func openLogFile() {
        if FileManager.default.fileExists(atPath: logFile.path) {
            NSWorkspace.shared.open(logFile)
        } else {
            showAlert(title: "Log File Not Found", message: "No activity log file found on Desktop")
        }
    }
    
    @objc func openReportFile() {
        if FileManager.default.fileExists(atPath: reportFile.path) {
            NSWorkspace.shared.open(reportFile)
        } else {
            showAlert(title: "Report File Not Found", message: "No report file found on Desktop. Generate a report first.")
        }
    }
    
    @objc func showAbout() {
        let aboutText = """
        TimeDeck
        Version: 0.0.1
        Author: Jeremy Roberts
        
        A simple menu bar app for tracking activities and time.
        
        Features:
        • Current activity tracking with live timer
        • Activity logging to Desktop files
        • End-of-day summaries and reports
        • Native Mac application
        
        Click menu items to access all functions.
        """
        
        showAlert(title: "About TimeDeck", message: aboutText)
    }
    
    func runAppleScript(_ scriptName: String, args: [String] = []) {
        // Get the bundle's Scripts directory
        guard let scriptsPath = Bundle.main.path(forResource: scriptName, ofType: "applescript") else {
            // Fallback to current directory for development
            let currentDir = FileManager.default.currentDirectoryPath
            let scriptPath = "\(currentDir)/\(scriptName).applescript"
            executeScript(at: scriptPath, args: args)
            return
        }
        
        executeScript(at: scriptsPath, args: args)
    }
    
    func executeScript(at path: String, args: [String]) {
        var command = ["/usr/bin/osascript", path]
        command.append(contentsOf: args)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [path] + args
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            showAlert(title: "Error", message: "Failed to run script: \(error.localizedDescription)")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func loadMenuBarIcon() -> NSImage? {
        // Try to load from bundle resources first
        if let bundleIconPath = Bundle.main.path(forResource: "menubar_icon", ofType: "png") {
            return NSImage(contentsOfFile: bundleIconPath)
        }
        
        // Try to load from icons directory for development
        let iconsDir = FileManager.default.currentDirectoryPath + "/icons"
        let possiblePaths = [
            "\(iconsDir)/menubar_icon.png",
            "\(iconsDir)/menubar_icon@2x.png"
        ]
        
        for iconPath in possiblePaths {
            if FileManager.default.fileExists(atPath: iconPath) {
                if let image = NSImage(contentsOfFile: iconPath) {
                    // Set the image to be template so it adapts to dark/light mode
                    image.isTemplate = true
                    return image
                }
            }
        }
        
        return nil
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = TimeDeckApp()
app.delegate = delegate
app.run()
