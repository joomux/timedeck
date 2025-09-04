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
        menu.addItem(NSMenuItem(title: "Activity Status", action: #selector(activityStatus), keyEquivalent: ""))
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
                    // Handle human-readable timestamp format: "YYYY-MM-DD HH:MM:SS activity name"
                    if lastLine.count > 19 && lastLine.prefix(4).allSatisfy(\.isNumber) {
                        let timestampStr = String(lastLine.prefix(19)) // "YYYY-MM-DD HH:MM:SS"
                        let activityName = String(lastLine.dropFirst(20)) // Skip timestamp and space
                        
                        // Parse the timestamp to calculate duration
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        
                        if let startDate = formatter.date(from: timestampStr) {
                            let duration = Int(Date().timeIntervalSince(startDate))
                            let hours = duration / 3600
                            let minutes = (duration % 3600) / 60
                            
                            currentActivityItem.title = "🟢 \(activityName) (\(hours)h \(minutes)m)"
                            return
                        }
                    } else {
                        // Fallback: try old UNIX timestamp format for backwards compatibility
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
    
    @objc func activityStatus() {
        runAppleScript("ActivityStatus")
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
        alert.informativeText = "This will permanently delete all activity data and cannot be undone. Are you sure?"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Clear All Data")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Clear the files directly from Swift to ensure it works
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            let logFile = homeDir.appendingPathComponent("Desktop/timedeck_log.txt")
            let reportFile = homeDir.appendingPathComponent("Desktop/timedeck_report.txt")
            
            // Remove the files
            try? FileManager.default.removeItem(at: logFile)
            try? FileManager.default.removeItem(at: reportFile)
            
            // Show success message
            showAlert(title: "Data Cleared Successfully", 
                     message: "✅ All activity data has been cleared.\n\nYou can now start tracking fresh activities.")
            
            // Update the current activity display
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
        Version: 0.0.2
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
        // Try to find script in the bundle's Scripts directory first
        let bundlePath = Bundle.main.bundlePath
        let scriptsDir = "\(bundlePath)/Contents/Scripts"
        let scriptPath = "\(scriptsDir)/\(scriptName).applescript"
        
        if FileManager.default.fileExists(atPath: scriptPath) {
            executeScript(at: scriptPath, args: args)
            return
        }
        
        // Fallback to current directory for development
        let currentDir = FileManager.default.currentDirectoryPath
        let fallbackPath = "\(currentDir)/\(scriptName).applescript"
        executeScript(at: fallbackPath, args: args)
    }
    
    func executeScript(at path: String, args: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [path] + args
        
        // Capture errors for user feedback
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Check for errors
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
                showAlert(title: "Script Error", message: "Script failed: \(errorOutput)")
            }
            
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
