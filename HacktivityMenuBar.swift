import Cocoa
import Foundation

@main
class HacktivityMenuBar: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var timer: Timer?
    
    let scriptDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Projects/hacktivity")
    let logFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/hacktivity_log.txt")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "📊"
        
        // Create menu
        menu = NSMenu()
        
        // Add menu items
        let currentActivityItem = NSMenuItem(title: "⚪ No active activity", action: nil, keyEquivalent: "")
        currentActivityItem.tag = 999 // Special tag for current activity item
        menu.addItem(currentActivityItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "📝 New Activity", action: #selector(newActivity), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "⏹️ End Activity", action: #selector(endActivity), keyEquivalent: "e"))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "📈 End Day Summary", action: #selector(endDay), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "📋 Generate Report", action: #selector(generateReport), keyEquivalent: "r"))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "🗑️ Start Fresh", action: #selector(startFresh), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "📁 Open Log File", action: #selector(openLogFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "📄 Open Report File", action: #selector(openReportFile), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        // Set all menu items' target to self
        for item in menu.items {
            item.target = self
        }
        
        // Start timer to update current activity
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.updateCurrentActivity()
        }
        
        updateCurrentActivity()
    }
    
    func updateCurrentActivity() {
        guard let currentActivityItem = menu.items.first(where: { $0.tag == 999 }) else { return }
        
        do {
            let logContent = try String(contentsOf: logFile)
            let lines = logContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            if let lastLine = lines.last, !lastLine.hasSuffix("END") {
                let components = lastLine.components(separatedBy: " ")
                if components.count >= 2,
                   let timestamp = Double(components[0]) {
                    let activityName = components.dropFirst().joined(separator: " ")
                    let duration = Int(Date().timeIntervalSince1970 - timestamp)
                    let hours = duration / 3600
                    let minutes = (duration % 3600) / 60
                    
                    currentActivityItem.title = "🟢 \(activityName) (\(hours)h \(minutes)m)"
                    statusItem.button?.title = "📊🟢"
                    return
                }
            }
        } catch {
            // Log file doesn't exist or can't be read
        }
        
        currentActivityItem.title = "⚪ No active activity"
        statusItem.button?.title = "📊"
    }
    
    @objc func newActivity() {
        let alert = NSAlert()
        alert.messageText = "New Activity"
        alert.informativeText = "Enter activity name:"
        alert.addButton(withTitle: "Start Activity")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "Activity name"
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn && !textField.stringValue.isEmpty {
            runAppleScript("NewActivity.applescript", arguments: [textField.stringValue])
            updateCurrentActivity()
        }
    }
    
    @objc func endActivity() {
        runAppleScript("EndActivity.applescript")
        updateCurrentActivity()
    }
    
    @objc func endDay() {
        runAppleScript("EndDay.applescript")
        updateCurrentActivity()
    }
    
    @objc func generateReport() {
        runAppleScript("GenerateReport.applescript")
    }
    
    @objc func startFresh() {
        let alert = NSAlert()
        alert.messageText = "Start Fresh"
        alert.informativeText = "This will clear all activity data. Are you sure?"
        alert.addButton(withTitle: "Yes, Clear All Data")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            runAppleScript("StartFresh.applescript")
            updateCurrentActivity()
        }
    }
    
    @objc func openLogFile() {
        NSWorkspace.shared.open(logFile)
    }
    
    @objc func openReportFile() {
        let reportFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/hacktivity_report.txt")
        NSWorkspace.shared.open(reportFile)
    }
    
    @objc func quit() {
        timer?.invalidate()
        NSApp.terminate(nil)
    }
    
    func runAppleScript(_ scriptName: String, arguments: [String] = []) {
        let scriptPath = scriptDirectory.appendingPathComponent(scriptName)
        
        var command = ["osascript", scriptPath.path]
        command.append(contentsOf: arguments)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [scriptPath.path] + arguments
        
        do {
            try process.run()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Failed to run script: \(error.localizedDescription)"
            alert.runModal()
        }
    }
}
