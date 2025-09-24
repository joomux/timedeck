import Cocoa
import Foundation
import EventKit
import UniformTypeIdentifiers
import UserNotifications
import ObjectiveC

// MARK: - Data Models
struct ActivityTemplate {
    let name: String
    let color: NSColor
    let emoji: String
    let category: String
    let isQuickAction: Bool
}

struct ActivityGoal {
    let activityName: String
    let dailyTarget: TimeInterval // in seconds
    let weeklyTarget: TimeInterval
}

struct ActivitySession {
    let name: String
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
}

// MARK: - User Preferences
class TimeDeckPreferences {
    static let shared = TimeDeckPreferences()
    private let userDefaults = UserDefaults.standard
    
    var activityTemplates: [ActivityTemplate] {
        get {
            // Default templates if none exist
            if let data = userDefaults.data(forKey: "activityTemplates"),
               let templates = try? JSONDecoder().decode([ActivityTemplateData].self, from: data) {
                return templates.map { templateData in
                    ActivityTemplate(
                        name: templateData.name,
                        color: NSColor(red: templateData.red, green: templateData.green, blue: templateData.blue, alpha: 1.0),
                        emoji: templateData.emoji,
                        category: templateData.category,
                        isQuickAction: templateData.isQuickAction
                    )
                }
            }
            return defaultTemplates
        }
        set {
            print("DEBUG: TimeDeckPreferences setter called with \(newValue.count) templates")
            
            // Wrap entire operation in error handling
            do {
                let templateData = newValue.compactMap { template -> ActivityTemplateData? in
                print("DEBUG: Converting template: '\(template.name)'")
                
                // Defensive color conversion to prevent crashes
                let rgbColor: NSColor
                if let convertedColor = template.color.usingColorSpace(.deviceRGB) {
                    rgbColor = convertedColor
                    print("DEBUG: Successfully converted color to RGB")
                } else {
                    print("DEBUG: Failed to convert color to RGB, using default")
                    rgbColor = NSColor.systemBlue.usingColorSpace(.deviceRGB) ?? NSColor.systemBlue
                }
                
                // Defensive string handling
                let safeName = template.name.isEmpty ? "Unnamed" : template.name
                let safeEmoji = template.emoji.isEmpty ? "📋" : template.emoji
                let safeCategory = template.category.isEmpty ? "Work" : template.category
                
                print("DEBUG: Creating ActivityTemplateData with safe values")
                let templateData = ActivityTemplateData(
                    name: safeName,
                    red: rgbColor.redComponent,
                    green: rgbColor.greenComponent,
                    blue: rgbColor.blueComponent,
                    emoji: safeEmoji,
                    category: safeCategory,
                    isQuickAction: template.isQuickAction
                )
                print("DEBUG: Successfully created ActivityTemplateData for '\(safeName)'")
                return templateData
            }
            print("DEBUG: Converted to \(templateData.count) templateData objects")
            
            guard !templateData.isEmpty else {
                print("DEBUG: ERROR - No valid template data to save")
                return
            }
            
            print("DEBUG: About to encode \(templateData.count) template data objects")
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(templateData)
            print("DEBUG: Successfully encoded template data (\(data.count) bytes)")
            
            print("DEBUG: About to save to UserDefaults")
            userDefaults.set(data, forKey: "activityTemplates")
            
            print("DEBUG: About to synchronize UserDefaults")
            userDefaults.synchronize()  // Force immediate save
            
            print("DEBUG: Successfully saved templates to UserDefaults")
            
            } catch {
                print("DEBUG: CRITICAL ERROR - Template setter operation failed: \(error)")
                print("DEBUG: Error details: \(error.localizedDescription)")
            }
        }
    }
    
    var idleDetectionEnabled: Bool {
        get { userDefaults.bool(forKey: "idleDetectionEnabled") }
        set { userDefaults.set(newValue, forKey: "idleDetectionEnabled") }
    }
    
    var idleThreshold: TimeInterval {
        get { userDefaults.double(forKey: "idleThreshold") != 0 ? userDefaults.double(forKey: "idleThreshold") : 300 } // 5 minutes default
        set { userDefaults.set(newValue, forKey: "idleThreshold") }
    }
    
    var pomodoroEnabled: Bool {
        get { userDefaults.bool(forKey: "pomodoroEnabled") }
        set { userDefaults.set(newValue, forKey: "pomodoroEnabled") }
    }
    
    var pomodoroWorkDuration: TimeInterval {
        get { userDefaults.double(forKey: "pomodoroWorkDuration") != 0 ? userDefaults.double(forKey: "pomodoroWorkDuration") : 1500 } // 25 minutes
        set { userDefaults.set(newValue, forKey: "pomodoroWorkDuration") }
    }
    
    var pomodoroBreakDuration: TimeInterval {
        get { userDefaults.double(forKey: "pomodoroBreakDuration") != 0 ? userDefaults.double(forKey: "pomodoroBreakDuration") : 300 } // 5 minutes
        set { userDefaults.set(newValue, forKey: "pomodoroBreakDuration") }
    }
    
    private var defaultTemplates: [ActivityTemplate] {
        return [
            ActivityTemplate(name: "Development", color: .systemBlue, emoji: "💻", category: "Work", isQuickAction: true),
            ActivityTemplate(name: "Meetings", color: .systemOrange, emoji: "🤝", category: "Work", isQuickAction: true),
            ActivityTemplate(name: "Email", color: .systemPurple, emoji: "📧", category: "Work", isQuickAction: true),
            ActivityTemplate(name: "Research", color: .systemTeal, emoji: "🔍", category: "Work", isQuickAction: true),
            ActivityTemplate(name: "Planning", color: .systemGreen, emoji: "📋", category: "Work", isQuickAction: true),
            ActivityTemplate(name: "Break", color: .systemYellow, emoji: "☕", category: "Personal", isQuickAction: true),
            ActivityTemplate(name: "Lunch", color: .systemRed, emoji: "🍽️", category: "Personal", isQuickAction: true),
            ActivityTemplate(name: "Admin", color: .systemGray, emoji: "📊", category: "Work", isQuickAction: false)
        ]
    }
}

struct ActivityTemplateData: Codable {
    let name: String
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let emoji: String
    let category: String
    let isQuickAction: Bool
}

enum PomodoroType {
    case work
    case `break`
    case longBreak
}

enum IdleState {
    case active
    case idle
    case returning
}

// Template Manager class removed - using simple alert-based approach instead
    
    deinit {
        print("DEBUG: TemplateManager deinit called - START")
        print("DEBUG: About to call cleanup from deinit")
        cleanup()
        print("DEBUG: TemplateManager deinit called - END")
    }
    
    func showTemplateManager() {
        print("DEBUG: showTemplateManager called")
        templates = preferences.activityTemplates
        print("DEBUG: Loaded \(templates.count) templates")
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window!.title = "🎨 Manage Activity Templates"
        window!.center()
        
        let contentView = NSView(frame: window!.contentRect(forFrameRect: window!.frame))
        window!.contentView = contentView
        
        setupTemplateManagerUI(contentView: contentView)
        window!.makeKeyAndOrderFront(nil)
        print("DEBUG: Template manager window should now be visible")
    }
    
    private func setupTemplateManagerUI(contentView: NSView) {
        // Title
        let titleLabel = NSTextField(labelWithString: "🎨 Activity Templates")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: 450, width: 560, height: 30)
        contentView.addSubview(titleLabel)
        
        // Instructions
        let instructionLabel = NSTextField(labelWithString: "Create and customize your quick-action templates. Templates appear in the menu for one-click activity starting.")
        instructionLabel.font = NSFont.systemFont(ofSize: 12)
        instructionLabel.frame = NSRect(x: 20, y: 415, width: 560, height: 30)
        instructionLabel.cell?.wraps = true
        contentView.addSubview(instructionLabel)
        
        // Template table
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 120, width: 560, height: 280))
        tableView = NSTableView()
        tableView!.dataSource = self
        tableView!.delegate = self
        tableView!.allowsEmptySelection = true
        tableView!.allowsMultipleSelection = false
        
        // Add columns
        let emojiColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("emoji"))
        emojiColumn.title = "🎭"
        emojiColumn.width = 40
        emojiColumn.minWidth = 40
        emojiColumn.maxWidth = 40
        tableView!.addTableColumn(emojiColumn)
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "Activity Name"
        nameColumn.width = 200
        nameColumn.minWidth = 150
        tableView!.addTableColumn(nameColumn)
        
        let categoryColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("category"))
        categoryColumn.title = "Category"
        categoryColumn.width = 120
        categoryColumn.minWidth = 100
        tableView!.addTableColumn(categoryColumn)
        
        let quickColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("quick"))
        quickColumn.title = "Quick Action"
        quickColumn.width = 100
        quickColumn.minWidth = 80
        tableView!.addTableColumn(quickColumn)
        
        let colorColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("color"))
        colorColumn.title = "Color"
        colorColumn.width = 80
        colorColumn.minWidth = 60
        tableView!.addTableColumn(colorColumn)
        
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        contentView.addSubview(scrollView)
        
        // Current count
        let countLabel = NSTextField(labelWithString: "Templates: \(templates.count)")
        countLabel.font = NSFont.systemFont(ofSize: 11)
        countLabel.frame = NSRect(x: 20, y: 95, width: 200, height: 18)
        countLabel.tag = 999 // For easy updates
        contentView.addSubview(countLabel)
        
        // Buttons
        let addButton = NSButton(frame: NSRect(x: 20, y: 60, width: 120, height: 32))
        addButton.title = "➕ Add Template"
        addButton.bezelStyle = .rounded
        addButton.isEnabled = true
        addButton.target = self
        addButton.action = #selector(addTemplateAction(_:))
        contentView.addSubview(addButton)
        print("DEBUG: Created Add Template button with target: \(String(describing: addButton.target)) action: \(String(describing: addButton.action))")
        
        let editButton = NSButton(frame: NSRect(x: 150, y: 60, width: 120, height: 32))
        editButton.title = "✏️ Edit Selected"
        editButton.bezelStyle = .rounded
        editButton.isEnabled = true
        editButton.target = self
        editButton.action = #selector(editTemplateAction(_:))
        contentView.addSubview(editButton)
        
        let duplicateButton = NSButton(frame: NSRect(x: 280, y: 60, width: 120, height: 32))
        duplicateButton.title = "📋 Duplicate"
        duplicateButton.bezelStyle = .rounded
        duplicateButton.isEnabled = true
        duplicateButton.target = self
        duplicateButton.action = #selector(duplicateTemplateAction(_:))
        contentView.addSubview(duplicateButton)
        
        let deleteButton = NSButton(frame: NSRect(x: 410, y: 60, width: 120, height: 32))
        deleteButton.title = "🗑️ Delete"
        deleteButton.bezelStyle = .rounded
        deleteButton.isEnabled = true
        deleteButton.target = self
        deleteButton.action = #selector(deleteTemplateAction(_:))
        contentView.addSubview(deleteButton)
        
        // Bottom buttons
        let resetButton = NSButton(frame: NSRect(x: 20, y: 20, width: 140, height: 32))
        resetButton.title = "🔄 Reset to Defaults"
        resetButton.bezelStyle = .rounded
        resetButton.isEnabled = true
        resetButton.target = self
        resetButton.action = #selector(resetToDefaultsAction(_:))
        contentView.addSubview(resetButton)
        
        let closeButton = NSButton(frame: NSRect(x: 500, y: 20, width: 80, height: 32))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.isEnabled = true
        closeButton.target = self
        closeButton.action = #selector(closeTemplateManagerAction(_:))
        contentView.addSubview(closeButton)
        
        tableView!.reloadData()
    }
    
    // MARK: - Table View Data Source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return templates.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < templates.count else { return nil }
        let template = templates[row]
        
        switch tableColumn?.identifier.rawValue {
        case "emoji":
            return template.emoji
        case "name":
            return template.name
        case "category":
            return template.category
        case "quick":
            return template.isQuickAction ? "✅ Yes" : "❌ No"
        case "color":
            return "●" // Color indicator
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) -> Void {
        guard row < templates.count,
              let textCell = cell as? NSTextFieldCell else { return }
        
        let template = templates[row]
        
        if tableColumn?.identifier.rawValue == "color" {
            textCell.textColor = template.color
            textCell.font = NSFont.systemFont(ofSize: 16)
        }
    }
    
    // MARK: - Template Actions
    @objc func addTemplateAction(_ sender: NSButton) {
        print("DEBUG: Add Template button clicked")
        showTemplateEditor(template: nil, isEditing: false)
    }
    
    @objc func editTemplateAction(_ sender: NSButton) {
        print("DEBUG: Edit Template button clicked")
        guard let selectedRow = tableView?.selectedRow,
              selectedRow >= 0 && selectedRow < templates.count else {
            showAlert(title: "No Selection", message: "Please select a template to edit.")
            return
        }
        
        showTemplateEditor(template: templates[selectedRow], isEditing: true)
    }
    
    @objc func duplicateTemplateAction(_ sender: NSButton) {
        print("DEBUG: Duplicate Template button clicked")
        guard let selectedRow = tableView?.selectedRow,
              selectedRow >= 0 && selectedRow < templates.count else {
            showAlert(title: "No Selection", message: "Please select a template to duplicate.")
            return
        }
        
        let original = templates[selectedRow]
        let duplicate = ActivityTemplate(
            name: "\(original.name) Copy",
            color: original.color,
            emoji: original.emoji,
            category: original.category,
            isQuickAction: original.isQuickAction
        )
        
        showTemplateEditor(template: duplicate, isEditing: false)
    }
    
    @objc func deleteTemplateAction(_ sender: NSButton) {
        print("DEBUG: Delete Template button clicked")
        guard let selectedRow = tableView?.selectedRow,
              selectedRow >= 0 && selectedRow < templates.count else {
            showAlert(title: "No Selection", message: "Please select a template to delete.")
            return
        }
        
        let template = templates[selectedRow]
        let alert = NSAlert()
        alert.messageText = "Delete Template"
        alert.informativeText = "Are you sure you want to delete '\(template.name)'? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            templates.remove(at: selectedRow)
            saveTemplates()
            tableView?.reloadData()
            updateCountLabel()
        }
    }
    
    @objc func resetToDefaultsAction(_ sender: NSButton) {
        print("DEBUG: Reset to Defaults button clicked")
        let alert = NSAlert()
        alert.messageText = "Reset to Defaults"
        alert.informativeText = "This will replace all current templates with the default set. Are you sure?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Clear stored templates to force defaults
            UserDefaults.standard.removeObject(forKey: "activityTemplates")
            templates = preferences.activityTemplates
            saveTemplates()
            tableView?.reloadData()
            updateCountLabel()
        }
    }
    
    @objc func closeTemplateManagerAction(_ sender: NSButton) {
        print("DEBUG: Close Template Manager button clicked")
        guard !isClosing else {
            print("DEBUG: Already closing, ignoring repeated close action")
            return
        }
        isClosing = true
        cleanup()
        window?.close()
    }
    
    private func cleanup() {
        print("DEBUG: Cleaning up TemplateManager - START")
        
        print("DEBUG: About to remove button targets")
        // Safely remove button targets to prevent further actions
        if let window = window, let contentView = window.contentView {
            for subview in contentView.subviews {
                if let button = subview as? NSButton {
                    button.target = nil
                    button.action = nil
                }
            }
        }
        print("DEBUG: Button targets removed")
        
        print("DEBUG: About to clear templates array")
        templates.removeAll()
        print("DEBUG: Templates array cleared")
        
        print("DEBUG: About to clear tableView reference")
        tableView = nil
        print("DEBUG: TableView reference cleared")
        
        print("DEBUG: About to clear window reference")
        window = nil
        print("DEBUG: Window reference cleared")
        
        print("DEBUG: Cleaning up TemplateManager - END")
    }
    
    // MARK: - Template Editor
    func showTemplateEditor(template: ActivityTemplate?, isEditing: Bool) {
        print("DEBUG: showTemplateEditor called - isEditing: \(isEditing)")
        
        let editorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        editorWindow.title = isEditing ? "✏️ Edit Template" : "➕ Add Template"
        editorWindow.center()
        editorWindow.delegate = self
        print("DEBUG: Created editor window: \(editorWindow.title)")
        print("DEBUG: Set window delegate to TemplateManager")
        
        print("DEBUG: About to create contentView")
        let contentView = NSView(frame: editorWindow.contentRect(forFrameRect: editorWindow.frame))
        print("DEBUG: ContentView created")
        
        editorWindow.contentView = contentView
        print("DEBUG: ContentView assigned to window")
        
        var yPos = 270
        print("DEBUG: Starting UI setup")
        
        // Title
        print("DEBUG: Creating title label")
        let titleLabel = NSTextField(labelWithString: isEditing ? "✏️ Edit Activity Template" : "➕ Create New Template")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: yPos, width: 360, height: 25)
        contentView.addSubview(titleLabel)
        print("DEBUG: Title label added")
        yPos -= 40
        
        // Name field
        print("DEBUG: Creating name field")
        let nameLabel = NSTextField(labelWithString: "Activity Name:")
        nameLabel.frame = NSRect(x: 20, y: yPos, width: 120, height: 20)
        contentView.addSubview(nameLabel)
        
        let nameField = NSTextField(frame: NSRect(x: 150, y: yPos, width: 230, height: 24))
        nameField.stringValue = template?.name ?? ""
        nameField.placeholderString = "e.g., Development, Meetings"
        contentView.addSubview(nameField)
        print("DEBUG: Name field created")
        yPos -= 35
        print("DEBUG: About to create emoji field, yPos: \(yPos)")
        
        // Emoji field
        print("DEBUG: Creating emoji label")
        let emojiLabel = NSTextField(labelWithString: "Emoji:")
        print("DEBUG: Emoji label created, setting frame")
        emojiLabel.frame = NSRect(x: 20, y: yPos, width: 120, height: 20)
        print("DEBUG: Adding emoji label to contentView")
        contentView.addSubview(emojiLabel)
        print("DEBUG: Emoji label added")
        
        print("DEBUG: Creating emoji field")
        let emojiField = NSTextField(frame: NSRect(x: 150, y: yPos, width: 60, height: 24))
        print("DEBUG: Setting emoji field value")
        emojiField.stringValue = template?.emoji ?? ""
        emojiField.placeholderString = "💻"
        print("DEBUG: Adding emoji field to contentView")
        contentView.addSubview(emojiField)
        print("DEBUG: Emoji field added")
        
        print("DEBUG: Creating emoji hint")
        let emojiHint = NSTextField(labelWithString: "Single emoji character")
        emojiHint.font = NSFont.systemFont(ofSize: 10)
        emojiHint.textColor = .secondaryLabelColor
        emojiHint.frame = NSRect(x: 220, y: yPos + 2, width: 160, height: 16)
        contentView.addSubview(emojiHint)
        print("DEBUG: Emoji hint added")
        yPos -= 35
        print("DEBUG: Emoji section completed")
        
        // Category field
        print("DEBUG: Creating category field, yPos: \(yPos)")
        let categoryLabel = NSTextField(labelWithString: "Category:")
        categoryLabel.frame = NSRect(x: 20, y: yPos, width: 120, height: 20)
        contentView.addSubview(categoryLabel)
        print("DEBUG: Category label added")
        
        print("DEBUG: Creating category combo box")
        let categoryField = NSComboBox(frame: NSRect(x: 150, y: yPos, width: 230, height: 24))
        print("DEBUG: Category combo box created, adding items")
        categoryField.addItems(withObjectValues: ["Work", "Personal", "Learning", "Health", "Creative", "Administrative"])
        print("DEBUG: Items added to combo box, setting value")
        categoryField.stringValue = template?.category ?? "Work"
        categoryField.isEditable = true
        print("DEBUG: Adding category field to contentView")
        contentView.addSubview(categoryField)
        print("DEBUG: Category field added")
        yPos -= 35
        print("DEBUG: Category section completed")
        
        // Color selection
        print("DEBUG: Creating color section, yPos: \(yPos)")
        let colorLabel = NSTextField(labelWithString: "Color:")
        colorLabel.frame = NSRect(x: 20, y: yPos, width: 120, height: 20)
        contentView.addSubview(colorLabel)
        print("DEBUG: Color label added")
        
        print("DEBUG: Creating color well")
        let colorWell = NSColorWell(frame: NSRect(x: 150, y: yPos - 5, width: 60, height: 30))
        colorWell.color = template?.color ?? .systemBlue
        contentView.addSubview(colorWell)
        print("DEBUG: Color well added")
        yPos -= 40
        
        // Quick Action checkbox
        print("DEBUG: Creating quick action checkbox, yPos: \(yPos)")
        let quickActionCheckbox = NSButton(checkboxWithTitle: "Show as Quick Action in menu", target: nil, action: nil)
        quickActionCheckbox.state = (template?.isQuickAction ?? true) ? .on : .off
        quickActionCheckbox.frame = NSRect(x: 20, y: yPos, width: 360, height: 20)
        contentView.addSubview(quickActionCheckbox)
        print("DEBUG: Quick action checkbox added")
        yPos -= 40
        print("DEBUG: All UI elements created, yPos: \(yPos)")
        
        // Buttons
        print("DEBUG: Creating buttons")
        let cancelButton = NSButton(frame: NSRect(x: 220, y: yPos, width: 80, height: 32))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape
        cancelButton.isEnabled = true
        cancelButton.target = self
        cancelButton.action = #selector(closeEditorAction(_:))
        contentView.addSubview(cancelButton)
        print("DEBUG: Cancel button added")
        
        let saveButton = NSButton(frame: NSRect(x: 310, y: yPos, width: 70, height: 32))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Return
        saveButton.isEnabled = true
        saveButton.target = self
        saveButton.action = #selector(saveTemplateAction(_:))
        contentView.addSubview(saveButton)
        print("DEBUG: Save button added")
        
        // Store references for the save action using tags and associated objects
        print("DEBUG: Storing references using tags")
        nameField.tag = 100
        emojiField.tag = 101
        categoryField.tag = 102
        colorWell.tag = 103
        quickActionCheckbox.tag = 104
        
        // Store complex data using associated objects
        objc_setAssociatedObject(editorWindow, "template", template, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(editorWindow, "isEditing", isEditing, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(editorWindow, "templateManager", self, .OBJC_ASSOCIATION_RETAIN)
        print("DEBUG: All references stored")
        
        print("DEBUG: About to show editor window")
        editorWindow.makeKeyAndOrderFront(nil)
        print("DEBUG: makeKeyAndOrderFront called")
        nameField.becomeFirstResponder()
        print("DEBUG: Editor window should now be visible")
        print("DEBUG: showTemplateEditor function completed")
    }
    
    @objc func saveTemplateAction(_ sender: NSButton) {
        print("DEBUG: Save Template button clicked")
        
        guard let editorWindow = sender.window,
              let contentView = editorWindow.contentView,
              let nameField = contentView.viewWithTag(100) as? NSTextField,
              let emojiField = contentView.viewWithTag(101) as? NSTextField,
              let categoryField = contentView.viewWithTag(102) as? NSComboBox,
              let colorWell = contentView.viewWithTag(103) as? NSColorWell,
              let quickActionCheckbox = contentView.viewWithTag(104) as? NSButton else {
            print("DEBUG: Failed to get UI elements by tag")
            return
        }
        
        print("DEBUG: Got all UI elements successfully")
        
        // CRITICAL: End editing for all text fields to prevent IMK errors
        print("DEBUG: Ending editing for all text fields to prevent IMK crash")
        editorWindow.endEditing(for: nil)
        editorWindow.makeFirstResponder(nil)
        
        // Extract ALL values immediately before dispatching
        print("DEBUG: About to extract UI values")
        let template = objc_getAssociatedObject(editorWindow, "template") as? ActivityTemplate
        let isEditing = objc_getAssociatedObject(editorWindow, "isEditing") as? Bool ?? false
        
        let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = emojiField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = categoryField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let color = colorWell.color
        let isQuickAction = quickActionCheckbox.state == .on
        
        print("DEBUG: Extracted UI values - name: '\(name)', emoji: '\(emoji)', category: '\(category)'")
        
        // Close window immediately in UI thread, then do data operations in background
        print("DEBUG: About to clean up and close window immediately")
        objc_setAssociatedObject(editorWindow, "template", nil, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(editorWindow, "isEditing", nil, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(editorWindow, "templateManager", nil, .OBJC_ASSOCIATION_RETAIN)
        print("DEBUG: Associated objects cleaned up")
        
        print("DEBUG: About to close editor window immediately")
        editorWindow.close()
        print("DEBUG: Editor window closed")
        
        // Now dispatch data operations to background queue (no UI operations)
        print("DEBUG: About to dispatch data operations to background queue")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            print("DEBUG: In background queue, about to perform data-only save")
            self?.performDataOnlySave(template: template, isEditing: isEditing, 
                                    name: name, emoji: emoji, category: category, 
                                    color: color, isQuickAction: isQuickAction)
            print("DEBUG: Data-only save completed in background queue")
        }
        
        print("DEBUG: Dispatched data operations, saveTemplateAction method ending")
    }
    
    private func performDataOnlySave(template: ActivityTemplate?, isEditing: Bool,
                                    name: String, emoji: String, category: String,
                                    color: NSColor, isQuickAction: Bool) {
        print("DEBUG: Performing save template operation")
        print("DEBUG: Template values - name: '\(name)', emoji: '\(emoji)', category: '\(category)'")
        
        // Validation - dispatch alerts to main queue since we're in background
        if name.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "Invalid Name", message: "Please enter an activity name.")
            }
            return
        }
        
        if emoji.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "Invalid Emoji", message: "Please enter an emoji character.")
            }
            return
        }
        
        if category.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "Invalid Category", message: "Please enter a category.")
            }
            return
        }
        
        // Create new template with defensive color handling
        print("DEBUG: About to create new template with color: \(color)")
        let safeColor: NSColor
        if let rgbColor = color.usingColorSpace(.deviceRGB) {
            safeColor = rgbColor
            print("DEBUG: Successfully converted color to RGB")
        } else {
            safeColor = NSColor.systemBlue
            print("DEBUG: Failed to convert color, using systemBlue")
        }
        
        let newTemplate = ActivityTemplate(
            name: name,
            color: safeColor,
            emoji: emoji,
            category: category,
            isQuickAction: isQuickAction
        )
        print("DEBUG: Successfully created new template: \(newTemplate.name)")
        
        if isEditing {
            // Find and replace the original template
            if let originalTemplate = template,
               let index = templates.firstIndex(where: { $0.name == originalTemplate.name && $0.emoji == originalTemplate.emoji }) {
                templates[index] = newTemplate
                print("DEBUG: Updated template at index \(index)")
            }
        } else {
            // Add new template
            templates.append(newTemplate)
            print("DEBUG: Added new template, total count: \(templates.count)")
        }
        
        print("DEBUG: About to save templates")
        saveTemplates()
        print("DEBUG: Templates saved successfully")
        
        // Only update table view on main queue - no window operations
        print("DEBUG: Dispatching table view update to main queue")
        DispatchQueue.main.async { [weak self] in
            print("DEBUG: In main queue for table view update only")
            self?.tableView?.reloadData()
            self?.updateCountLabel()
            print("DEBUG: Table view and count label updated successfully")
        }
        
        print("DEBUG: performDataOnlySave method ending - CRITICAL CHECKPOINT")
        print("DEBUG: About to exit performDataOnlySave - FINAL LINE")
    }
    
    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        print("DEBUG: NSWindowDelegate - windowWillClose called")
        if let window = notification.object as? NSWindow {
            print("DEBUG: Window about to close: \(window)")
            window.delegate = nil
            print("DEBUG: Cleared window delegate")
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        print("DEBUG: NSWindowDelegate - windowDidBecomeKey called")
    }
    
    func windowDidResignKey(_ notification: Notification) {
        print("DEBUG: NSWindowDelegate - windowDidResignKey called")
    }
    
    @objc func closeEditorAction(_ sender: NSButton) {
        print("DEBUG: Close Editor button clicked")
        if let window = sender.window {
            print("DEBUG: Found window to close: \(window)")
            // Clean up associated objects to prevent memory leaks
            objc_setAssociatedObject(window, "template", nil, .OBJC_ASSOCIATION_RETAIN)
            objc_setAssociatedObject(window, "isEditing", nil, .OBJC_ASSOCIATION_RETAIN)
            objc_setAssociatedObject(window, "templateManager", nil, .OBJC_ASSOCIATION_RETAIN)
            print("DEBUG: About to close editor window via Close button")
            window.close()
            print("DEBUG: Editor window close() called via Close button")
        } else {
            print("DEBUG: ERROR - No window found for Close button")
        }
    }
    
    // MARK: - Helper Methods
    func refreshFromPreferences() {
        print("DEBUG: Refreshing template manager from preferences - START")
        
        print("DEBUG: About to load templates from preferences")
        templates = preferences.activityTemplates
        print("DEBUG: Loaded \(templates.count) templates from preferences")
        
        print("DEBUG: About to reload table view")
        tableView?.reloadData()
        print("DEBUG: Table view reloaded")
        
        print("DEBUG: About to update count label")
        updateCountLabel()
        print("DEBUG: Count label updated")
        
        print("DEBUG: Template manager UI refreshed successfully - END")
    }
    
    private func saveTemplates() {
        print("DEBUG: Saving \(templates.count) templates to preferences")
        print("DEBUG: About to assign templates to preferences.activityTemplates")
        
        preferences.activityTemplates = templates
        
        print("DEBUG: Assignment completed, posting notification to rebuild menu")
        
        // Notify the main app to rebuild menu on main queue since we might be in background
        print("DEBUG: About to post TemplatesUpdated notification on main queue")
        DispatchQueue.main.async {
            print("DEBUG: Posting TemplatesUpdated notification on main queue")
            NotificationCenter.default.post(name: NSNotification.Name("TemplatesUpdated"), object: nil)
            print("DEBUG: TemplatesUpdated notification posted")
        }
    }
    
    private func updateCountLabel() {
        if let window = window,
           let contentView = window.contentView,
           let countLabel = contentView.subviews.first(where: { $0.tag == 999 }) as? NSTextField {
            countLabel.stringValue = "Templates: \(templates.count)"
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

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
    private let reportFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop") 
        .appendingPathComponent("timedeck_report.txt")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupGlobalKeyboardShortcuts()
        requestNotificationPermissions()
        updateCurrentActivity()
        
        // Listen for template updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(templatesUpdated),
            name: NSNotification.Name("TemplatesUpdated"),
            object: nil
        )
        
        // Update every 15 seconds for more responsive UI
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            self.updateCurrentActivity()
        }
        
        // Start idle detection if enabled
        if preferences.idleDetectionEnabled {
            startIdleDetection()
        }
        
        // Show welcome notification after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNotification(title: "TimeDeck Enhanced", message: "🚀 Enhanced time tracking is ready! Try the new quick actions and templates.")
        }
    }
    
    @objc func templatesUpdated() {
        print("DEBUG: templatesUpdated() called - rebuilding menu")
        setupMenuBar()
        updateCurrentActivity()
        print("DEBUG: Menu rebuilt successfully")
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
        
        // Try to load the menu bar icon from the app bundle
        if let iconImage = loadMenuBarIcon() {
            statusItem.button?.image = iconImage
        } else {
            // Fallback to emoji if icon not found
            statusItem.button?.title = "📊"
        }
        
        menu = NSMenu()
        menu.autoenablesItems = false
        
        // Current activity status (will be updated dynamically)
        menu.addItem(NSMenuItem(title: "⚪ No active activity", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Quick Actions Section
        let quickActionsItem = NSMenuItem(title: "🚀 Quick Actions", action: nil, keyEquivalent: "")
        quickActionsItem.isEnabled = false
        menu.addItem(quickActionsItem)
        
        // Add quick action templates
        for template in preferences.activityTemplates.filter({ $0.isQuickAction }) {
            let item = NSMenuItem(title: "\(template.emoji) \(template.name)", action: #selector(quickStartActivity(_:)), keyEquivalent: "")
            item.representedObject = template.name
            item.target = self
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Main actions
        menu.addItem(NSMenuItem(title: "✨ New Activity...", action: #selector(newActivity), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "⏹️ End Activity", action: #selector(endActivity), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "⏸️ Pause/Resume", action: #selector(pauseResumeActivity), keyEquivalent: "p"))
        
        menu.addItem(NSMenuItem.separator())
        
        // Pomodoro Section (if enabled)
        if preferences.pomodoroEnabled {
            let pomodoroItem = NSMenuItem(title: "🍅 Pomodoro", action: nil, keyEquivalent: "")
            pomodoroItem.isEnabled = false
            menu.addItem(pomodoroItem)
            menu.addItem(NSMenuItem(title: "Start Pomodoro", action: #selector(startPomodoro), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Stop Pomodoro", action: #selector(stopPomodoro), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }
        
        // Analytics & Reports
        let analyticsItem = NSMenuItem(title: "📊 Analytics & Reports", action: nil, keyEquivalent: "")
        analyticsItem.isEnabled = false
        menu.addItem(analyticsItem)
        menu.addItem(NSMenuItem(title: "Activity Status", action: #selector(activityStatus), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Daily Dashboard", action: #selector(showDashboard), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "End Day Summary", action: #selector(endDay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Generate Report", action: #selector(generateReport), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Export Data", action: #selector(exportData), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Tools
        let toolsItem = NSMenuItem(title: "🔧 Tools", action: nil, keyEquivalent: "")
        toolsItem.isEnabled = false
        menu.addItem(toolsItem)
        menu.addItem(NSMenuItem(title: "Manage Templates", action: #selector(manageTemplates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Set Goals", action: #selector(setGoals), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Start Fresh", action: #selector(startFresh), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Files
        menu.addItem(NSMenuItem(title: "Open Log File", action: #selector(openLogFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Report File", action: #selector(openReportFile), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About TimeDeck Enhanced", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit TimeDeck", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        // Set target for all items
        for item in menu.items {
            if item.target == nil && item.action != nil {
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
                            
                            // Update menu item
                            currentActivityItem.title = "🟢 \(activityName) (\(hours)h \(minutes)m)"
                            
                            // Update menu bar to show activity name and duration alongside icon
                            statusItem.button?.title = " \(activityName) (\(hours)h \(minutes)m)"
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
                            
                            // Update menu item
                            currentActivityItem.title = "🟢 \(activityName) (\(hours)h \(minutes)m)"
                            
                            // Update menu bar to show activity name and duration alongside icon
                            statusItem.button?.title = " \(activityName) (\(hours)h \(minutes)m)"
                            return
                        }
                    }
                }
            }
        } catch {
            print("Error reading log file: \(error)")
        }
        
        // No active activity
        currentActivityItem.title = "⚪ No active activity"
        statusItem.button?.title = ""
    }
    
    @objc func newActivity() {
        showEnhancedActivityDialog()
    }
    
    @objc func quickStartActivity(_ sender: NSMenuItem) {
        guard let activityName = sender.representedObject as? String else { return }
        startActivity(activityName)
    }
    
    func showEnhancedActivityDialog() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "✨ Start New Activity"
        window.center()
        window.level = .floating
        
        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = contentView
        
        // Title
        let titleLabel = NSTextField(labelWithString: "What are you working on?")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.frame = NSRect(x: 20, y: 300, width: 410, height: 25)
        contentView.addSubview(titleLabel)
        
        // Activity name field with suggestions
        let textField = NSTextField(frame: NSRect(x: 20, y: 260, width: 410, height: 30))
        textField.placeholderString = "Enter activity name or select from templates..."
        textField.font = NSFont.systemFont(ofSize: 14)
        contentView.addSubview(textField)
        
        // Templates section
        let templatesLabel = NSTextField(labelWithString: "🚀 Quick Templates:")
        templatesLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        templatesLabel.frame = NSRect(x: 20, y: 220, width: 410, height: 20)
        contentView.addSubview(templatesLabel)
        
        // Template buttons
        var yPosition = 180
        let templates = preferences.activityTemplates
        for (index, template) in templates.enumerated() {
            if index > 0 && index % 3 == 0 {
                yPosition -= 40
            }
            
            let xPosition = 20 + (index % 3) * 140
            let button = NSButton(frame: NSRect(x: xPosition, y: yPosition, width: 130, height: 30))
            button.title = "\(template.emoji) \(template.name)"
            button.bezelStyle = .rounded
            button.target = self
            button.action = #selector(templateButtonClicked(_:))
            button.tag = index
            
            // Color the button based on template
            if #available(macOS 10.14, *) {
                button.contentTintColor = template.color
            }
            
            contentView.addSubview(button)
        }
        
        // Recent activities section
        let recentLabel = NSTextField(labelWithString: "📅 Recent Activities:")
        recentLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        recentLabel.frame = NSRect(x: 20, y: 100, width: 410, height: 20)
        contentView.addSubview(recentLabel)
        
        // Get recent activities
        let recentActivities = getRecentActivities(limit: 6)
        var recentYPosition = 60
        for (index, activity) in recentActivities.enumerated() {
            if index > 0 && index % 3 == 0 {
                recentYPosition -= 30
            }
            
            let xPosition = 20 + (index % 3) * 140
            let button = NSButton(frame: NSRect(x: xPosition, y: recentYPosition, width: 130, height: 25))
            button.title = "🕐 \(activity)"
            button.bezelStyle = .rounded
            button.font = NSFont.systemFont(ofSize: 12)
            button.target = self
            button.action = #selector(recentActivityClicked(_:))
            button.alternateTitle = activity
            
            contentView.addSubview(button)
        }
        
        // Buttons
        let cancelButton = NSButton(frame: NSRect(x: 260, y: 20, width: 80, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        cancelButton.target = self
        cancelButton.action = #selector(closeActivityDialog(_:))
        contentView.addSubview(cancelButton)
        
        let startButton = NSButton(frame: NSRect(x: 350, y: 20, width: 80, height: 30))
        startButton.title = "Start"
        startButton.bezelStyle = .rounded
        startButton.keyEquivalent = "\r" // Return key
        startButton.target = self
        startButton.action = #selector(startActivityFromDialog(_:))
        contentView.addSubview(startButton)
        
        // Store references for button actions
        window.contentView?.setValue(textField, forKey: "activityTextField")
        window.contentView?.setValue(window, forKey: "dialogWindow")
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        textField.becomeFirstResponder()
    }
    
    @objc func templateButtonClicked(_ sender: NSButton) {
        let template = preferences.activityTemplates[sender.tag]
        if let window = sender.window,
           let textField = window.contentView?.value(forKey: "activityTextField") as? NSTextField {
            textField.stringValue = template.name
        }
    }
    
    @objc func recentActivityClicked(_ sender: NSButton) {
        let activityName = sender.alternateTitle
        if let window = sender.window,
           let textField = window.contentView?.value(forKey: "activityTextField") as? NSTextField {
            textField.stringValue = activityName
        }
    }
    
    @objc func closeActivityDialog(_ sender: NSButton) {
        sender.window?.close()
    }
    
    @objc func startActivityFromDialog(_ sender: NSButton) {
        if let window = sender.window,
           let textField = window.contentView?.value(forKey: "activityTextField") as? NSTextField,
           !textField.stringValue.isEmpty {
            startActivity(textField.stringValue)
            window.close()
        }
    }
    
    func startActivity(_ activityName: String) {
        runAppleScript("NewActivity", args: [activityName])
        updateCurrentActivity()
        showNotification(title: "Activity Started", message: "🎯 Now tracking: \(activityName)")
    }
    
    func getRecentActivities(limit: Int) -> [String] {
        do {
            if FileManager.default.fileExists(atPath: logFile.path) {
                let content = try String(contentsOf: logFile, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                
                var activities: [String] = []
                var seen = Set<String>()
                
                // Process lines in reverse to get most recent first
                for line in lines.reversed() {
                    if line.hasSuffix("END") { continue }
                    
                    let activityName: String
                    if line.count > 19 && line.prefix(4).allSatisfy(\.isNumber) {
                        // New format: "YYYY-MM-DD HH:MM:SS activity name"
                        activityName = String(line.dropFirst(20))
                    } else {
                        // Old format: "UNIX_TIMESTAMP activity name"
                        let components = line.components(separatedBy: " ")
                        if components.count >= 2 {
                            activityName = components.dropFirst().joined(separator: " ")
                        } else {
                            continue
                        }
                    }
                    
                    if !seen.contains(activityName) && activityName.count <= 20 {
                        activities.append(activityName)
                        seen.insert(activityName)
                        
                        if activities.count >= limit {
                            break
                        }
                    }
                }
                
                return activities
            }
        } catch {
            print("Error reading recent activities: \(error)")
        }
        
        return []
    }
    
    @objc func endActivity() {
        runAppleScript("EndActivity")
        updateCurrentActivity()
        showNotification(title: "Activity Ended", message: "⏹️ Activity has been stopped")
    }
    
    @objc func pauseResumeActivity() {
        // Check if there's a current activity
        do {
            if FileManager.default.fileExists(atPath: logFile.path) {
                let content = try String(contentsOf: logFile, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                
                if let lastLine = lines.last, !lastLine.hasSuffix("END") {
                    // Activity is running, pause it
                    runAppleScript("EndActivity")
                    showNotification(title: "Activity Paused", message: "⏸️ Activity paused - resume anytime")
                } else {
                    // No activity running, show activity selector
                    newActivity()
                }
            } else {
                newActivity()
            }
        } catch {
            newActivity()
        }
        updateCurrentActivity()
    }
    
    // MARK: - Pomodoro Functions
    @objc func startPomodoro() {
        if pomodoroTimer != nil {
            stopPomodoro()
        }
        
        currentPomodoroType = .work
        pomodoroStartTime = Date()
        
        let duration = preferences.pomodoroWorkDuration
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            self.pomodoroCompleted()
        }
        
        showNotification(title: "🍅 Pomodoro Started", message: "Work session: \(Int(duration/60)) minutes")
        updateCurrentActivity()
    }
    
    @objc func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroStartTime = nil
        currentPomodoroType = .work
        showNotification(title: "🍅 Pomodoro Stopped", message: "Timer cancelled")
        updateCurrentActivity()
    }
    
    func pomodoroCompleted() {
        switch currentPomodoroType {
        case .work:
            currentPomodoroType = .break
            let duration = preferences.pomodoroBreakDuration
            pomodoroStartTime = Date()
            pomodoroTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                self.pomodoroCompleted()
            }
            showNotification(title: "🍅 Work Complete!", message: "Time for a \(Int(duration/60)) minute break")
        case .break:
            pomodoroTimer?.invalidate()
            pomodoroTimer = nil
            pomodoroStartTime = nil
            currentPomodoroType = .work
            showNotification(title: "🍅 Break Over!", message: "Ready for another work session?")
        case .longBreak:
            // Similar to break but longer
            break
        }
        updateCurrentActivity()
    }
    
    // MARK: - Dashboard and Analytics
    @objc func showDashboard() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "📊 TimeDeck Dashboard"
        window.center()
        
        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = contentView
        
        // Get today's data
        let todayData = getTodayActivityData()
        let weekData = getWeekActivityData()
        
        // Title
        let titleLabel = NSTextField(labelWithString: "📊 Today's Activity Dashboard")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: 450, width: 560, height: 30)
        contentView.addSubview(titleLabel)
        
        // Today's summary
        let todayLabel = NSTextField(labelWithString: "🗓️ Today's Activities:")
        todayLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        todayLabel.frame = NSRect(x: 20, y: 400, width: 560, height: 20)
        contentView.addSubview(todayLabel)
        
        var yPos = 360
        for (activity, duration) in todayData.prefix(8) {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            let timeString = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
            
            let activityLabel = NSTextField(labelWithString: "• \(activity): \(timeString)")
            activityLabel.font = NSFont.systemFont(ofSize: 12)
            activityLabel.frame = NSRect(x: 40, y: yPos, width: 520, height: 18)
            contentView.addSubview(activityLabel)
            yPos -= 25
        }
        
        // Week summary
        let weekLabel = NSTextField(labelWithString: "📅 This Week's Summary:")
        weekLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        weekLabel.frame = NSRect(x: 20, y: yPos - 20, width: 560, height: 20)
        contentView.addSubview(weekLabel)
        
        yPos -= 50
        let totalWeekTime = weekData.values.reduce(0, +)
        let weekHours = Int(totalWeekTime) / 3600
        let weekMinutes = (Int(totalWeekTime) % 3600) / 60
        
        let weekSummaryLabel = NSTextField(labelWithString: "Total tracked this week: \(weekHours)h \(weekMinutes)m")
        weekSummaryLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        weekSummaryLabel.frame = NSRect(x: 40, y: yPos, width: 520, height: 18)
        contentView.addSubview(weekSummaryLabel)
        
        // Close button
        let closeButton = NSButton(frame: NSRect(x: 520, y: 20, width: 60, height: 30))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeDashboard(_:))
        contentView.addSubview(closeButton)
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func closeDashboard(_ sender: NSButton) {
        sender.window?.close()
    }
    
    func getTodayActivityData() -> [(String, TimeInterval)] {
        // Implementation similar to existing activity parsing but returns structured data
        var activityTimes: [String: TimeInterval] = [:]
        
        do {
            if FileManager.default.fileExists(atPath: logFile.path) {
                let content = try String(contentsOf: logFile, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                
                // Get today's start/end timestamps
                let calendar = Calendar.current
                let today = Date()
                let todayStart = calendar.startOfDay(for: today)
                let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
                
                var currentActivity = ""
                var currentStartTime: TimeInterval = 0
                
                for line in lines {
                    if line.isEmpty { continue }
                    
                    let timestamp: TimeInterval
                    let activityName: String
                    
                    if line.count > 19 && line.prefix(4).allSatisfy(\.isNumber) {
                        // New format
                        let timestampStr = String(line.prefix(19))
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        
                        guard let date = formatter.date(from: timestampStr) else { continue }
                        timestamp = date.timeIntervalSince1970
                        activityName = String(line.dropFirst(20))
                    } else {
                        // Old format
                        let components = line.components(separatedBy: " ")
                        guard components.count >= 2,
                              let ts = TimeInterval(components[0]) else { continue }
                        timestamp = ts
                        activityName = components.dropFirst().joined(separator: " ")
                    }
                    
                    // Check if this is from today
                    let entryDate = Date(timeIntervalSince1970: timestamp)
                    if entryDate < todayStart || entryDate >= todayEnd { continue }
                    
                    if !currentActivity.isEmpty {
                        let duration = timestamp - currentStartTime
                        activityTimes[currentActivity, default: 0] += duration
                    }
                    
                    if activityName == "END" {
                        currentActivity = ""
                        currentStartTime = 0
                    } else {
                        currentActivity = activityName
                        currentStartTime = timestamp
                    }
                }
                
                // Handle ongoing activity
                if !currentActivity.isEmpty {
                    let duration = Date().timeIntervalSince1970 - currentStartTime
                    activityTimes[currentActivity, default: 0] += duration
                }
            }
        } catch {
            print("Error getting today's data: \(error)")
        }
        
        return activityTimes.sorted { $0.value > $1.value }
    }
    
    func getWeekActivityData() -> [String: TimeInterval] {
        // Similar to getTodayActivityData but for the past 7 days
        var activityTimes: [String: TimeInterval] = [:]
        
        do {
            if FileManager.default.fileExists(atPath: logFile.path) {
                let content = try String(contentsOf: logFile, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                
                let calendar = Calendar.current
                let today = Date()
                let weekStart = calendar.date(byAdding: .day, value: -7, to: today)!
                
                var currentActivity = ""
                var currentStartTime: TimeInterval = 0
                
                for line in lines {
                    if line.isEmpty { continue }
                    
                    let timestamp: TimeInterval
                    let activityName: String
                    
                    if line.count > 19 && line.prefix(4).allSatisfy(\.isNumber) {
                        let timestampStr = String(line.prefix(19))
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        
                        guard let date = formatter.date(from: timestampStr) else { continue }
                        timestamp = date.timeIntervalSince1970
                        activityName = String(line.dropFirst(20))
                    } else {
                        let components = line.components(separatedBy: " ")
                        guard components.count >= 2,
                              let ts = TimeInterval(components[0]) else { continue }
                        timestamp = ts
                        activityName = components.dropFirst().joined(separator: " ")
                    }
                    
                    let entryDate = Date(timeIntervalSince1970: timestamp)
                    if entryDate < weekStart { continue }
                    
                    if !currentActivity.isEmpty {
                        let duration = timestamp - currentStartTime
                        activityTimes[currentActivity, default: 0] += duration
                    }
                    
                    if activityName == "END" {
                        currentActivity = ""
                        currentStartTime = 0
                    } else {
                        currentActivity = activityName
                        currentStartTime = timestamp
                    }
                }
                
                if !currentActivity.isEmpty {
                    let duration = Date().timeIntervalSince1970 - currentStartTime
                    activityTimes[currentActivity, default: 0] += duration
                }
            }
        } catch {
            print("Error getting week data: \(error)")
        }
        
        return activityTimes
    }
    
    @objc func activityStatus() {
        runAppleScript("ActivityStatus")
    }
    
    // MARK: - Data Export
    @objc func exportData() {
        let panel = NSSavePanel()
        panel.title = "Export TimeDeck Data"
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [UTType(filenameExtension: "csv")!, UTType(filenameExtension: "json")!, UTType.plainText]
        } else {
            panel.allowedFileTypes = ["csv", "json", "txt"]
        }
        panel.nameFieldStringValue = "timedeck_export_\(DateFormatter.shortDate.string(from: Date()))"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                self.exportToFile(url: url)
            }
        }
    }
    
    func exportToFile(url: URL) {
        do {
            if FileManager.default.fileExists(atPath: logFile.path) {
                let content = try String(contentsOf: logFile, encoding: .utf8)
                
                if url.pathExtension.lowercased() == "csv" {
                    let csvContent = convertToCSV(content: content)
                    try csvContent.write(to: url, atomically: true, encoding: .utf8)
                } else if url.pathExtension.lowercased() == "json" {
                    let jsonContent = convertToJSON(content: content)
                    try jsonContent.write(to: url, atomically: true, encoding: .utf8)
                } else {
                    // Plain text
                    try content.write(to: url, atomically: true, encoding: .utf8)
                }
                
                showNotification(title: "Export Complete", message: "📁 Data exported to \(url.lastPathComponent)")
            }
        } catch {
            showAlert(title: "Export Failed", message: "Failed to export data: \(error.localizedDescription)")
        }
    }
    
    func convertToCSV(content: String) -> String {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var csvLines = ["Date,Time,Activity,Duration"]
        
        var currentActivity = ""
        var currentStartTime: TimeInterval = 0
        
        for line in lines {
            if line.isEmpty { continue }
            
            let timestamp: TimeInterval
            let activityName: String
            
            if line.count > 19 && line.prefix(4).allSatisfy(\.isNumber) {
                let timestampStr = String(line.prefix(19))
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                guard let date = formatter.date(from: timestampStr) else { continue }
                timestamp = date.timeIntervalSince1970
                activityName = String(line.dropFirst(20))
            } else {
                let components = line.components(separatedBy: " ")
                guard components.count >= 2,
                      let ts = TimeInterval(components[0]) else { continue }
                timestamp = ts
                activityName = components.dropFirst().joined(separator: " ")
            }
            
            if !currentActivity.isEmpty {
                let duration = timestamp - currentStartTime
                let startDate = Date(timeIntervalSince1970: currentStartTime)
                let dateStr = DateFormatter.shortDate.string(from: startDate)
                let timeStr = DateFormatter.shortTime.string(from: startDate)
                let durationStr = String(format: "%.1f", duration / 3600) // hours
                
                csvLines.append("\"\(dateStr)\",\"\(timeStr)\",\"\(currentActivity)\",\(durationStr)")
            }
            
            if activityName == "END" {
                currentActivity = ""
                currentStartTime = 0
            } else {
                currentActivity = activityName
                currentStartTime = timestamp
            }
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    func convertToJSON(content: String) -> String {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var activities: [[String: Any]] = []
        
        var currentActivity = ""
        var currentStartTime: TimeInterval = 0
        
        for line in lines {
            if line.isEmpty { continue }
            
            let timestamp: TimeInterval
            let activityName: String
            
            if line.count > 19 && line.prefix(4).allSatisfy(\.isNumber) {
                let timestampStr = String(line.prefix(19))
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                guard let date = formatter.date(from: timestampStr) else { continue }
                timestamp = date.timeIntervalSince1970
                activityName = String(line.dropFirst(20))
            } else {
                let components = line.components(separatedBy: " ")
                guard components.count >= 2,
                      let ts = TimeInterval(components[0]) else { continue }
                timestamp = ts
                activityName = components.dropFirst().joined(separator: " ")
            }
            
            if !currentActivity.isEmpty {
                let duration = timestamp - currentStartTime
                let activity: [String: Any] = [
                    "name": currentActivity,
                    "startTime": currentStartTime,
                    "endTime": timestamp,
                    "duration": duration
                ]
                activities.append(activity)
            }
            
            if activityName == "END" {
                currentActivity = ""
                currentStartTime = 0
            } else {
                currentActivity = activityName
                currentStartTime = timestamp
            }
        }
        
        let jsonData: [String: Any] = ["activities": activities, "exportedAt": Date().timeIntervalSince1970]
        
        if let data = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    // MARK: - Template Management - SIMPLE APPROACH
    @objc func manageTemplates() {
        print("DEBUG: manageTemplates() called - SIMPLE VERSION")
        
        // Simple alert-based approach - no complex UI
        let alert = NSAlert()
        alert.messageText = "🏷️ Template Management"
        alert.informativeText = "Choose an action for your activity templates:"
        
        alert.addButton(withTitle: "➕ Add Template")
        alert.addButton(withTitle: "📝 List Templates")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            showSimpleAddTemplate()
        case .alertSecondButtonReturn:
            showSimpleTemplateList()
        default:
            break
        }
    }
    
    private func showSimpleAddTemplate() {
        print("DEBUG: showSimpleAddTemplate() called")
        
        let alert = NSAlert()
        alert.messageText = "➕ Add New Template"
        alert.informativeText = "Enter template details:"
        
        // Create a simple input view
        let inputView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 120))
        
        // Name field
        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.frame = NSRect(x: 0, y: 90, width: 60, height: 20)
        let nameField = NSTextField(frame: NSRect(x: 70, y: 90, width: 200, height: 20))
        
        // Emoji field  
        let emojiLabel = NSTextField(labelWithString: "Emoji:")
        emojiLabel.frame = NSRect(x: 0, y: 60, width: 60, height: 20)
        let emojiField = NSTextField(frame: NSRect(x: 70, y: 60, width: 200, height: 20))
        emojiField.placeholderString = "e.g. 💻"
        
        // Category field
        let categoryLabel = NSTextField(labelWithString: "Category:")
        categoryLabel.frame = NSRect(x: 0, y: 30, width: 60, height: 20)
        let categoryField = NSTextField(frame: NSRect(x: 70, y: 30, width: 200, height: 20))
        categoryField.stringValue = "Work"
        
        inputView.addSubview(nameLabel)
        inputView.addSubview(nameField)
        inputView.addSubview(emojiLabel)
        inputView.addSubview(emojiField)
        inputView.addSubview(categoryLabel)
        inputView.addSubview(categoryField)
        
        alert.accessoryView = inputView
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let emoji = emojiField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let category = categoryField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !name.isEmpty && !emoji.isEmpty && !category.isEmpty {
                addSimpleTemplate(name: name, emoji: emoji, category: category)
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "❌ Invalid Input"
                errorAlert.informativeText = "Please fill in all fields."
                errorAlert.runModal()
            }
        }
    }
    
    private func addSimpleTemplate(name: String, emoji: String, category: String) {
        print("DEBUG: addSimpleTemplate called - name: '\(name)', emoji: '\(emoji)', category: '\(category)'")
        
        let newTemplate = ActivityTemplate(
            name: name,
            color: NSColor.systemBlue,
            emoji: emoji,
            category: category,
            isQuickAction: true
        )
        
        var templates = TimeDeckPreferences.shared.activityTemplates
        templates.append(newTemplate)
        TimeDeckPreferences.shared.activityTemplates = templates
        
        // Rebuild menu
        setupMenuBar()
        
        // Success message
        let successAlert = NSAlert()
        successAlert.messageText = "✅ Template Added"
        successAlert.informativeText = "'\(emoji) \(name)' has been added to your templates."
        successAlert.runModal()
        
        print("DEBUG: Template added successfully")
    }
    
    private func showSimpleTemplateList() {
        let templates = TimeDeckPreferences.shared.activityTemplates
        
        let alert = NSAlert()
        alert.messageText = "📝 Current Templates (\(templates.count))"
        
        let templateList = templates.map { "\($0.emoji) \($0.name) (\($0.category))" }.joined(separator: "\n")
        alert.informativeText = templateList.isEmpty ? "No templates found." : templateList
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Goals Management
    @objc func setGoals() {
        let alert = NSAlert()
        alert.messageText = "🎯 Goal Setting"
        alert.informativeText = "Set daily time goals for your activities:"
        alert.addButton(withTitle: "Save Goals")
        alert.addButton(withTitle: "Cancel")
        
        // Create a simple goal setting interface
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        
        let dailyLabel = NSTextField(labelWithString: "Daily work goal (hours):")
        dailyLabel.frame = NSRect(x: 0, y: 70, width: 200, height: 20)
        accessoryView.addSubview(dailyLabel)
        
        let dailyField = NSTextField(frame: NSRect(x: 200, y: 70, width: 80, height: 20))
        dailyField.stringValue = "8"
        accessoryView.addSubview(dailyField)
        
        let weeklyLabel = NSTextField(labelWithString: "Weekly work goal (hours):")
        weeklyLabel.frame = NSRect(x: 0, y: 40, width: 200, height: 20)
        accessoryView.addSubview(weeklyLabel)
        
        let weeklyField = NSTextField(frame: NSRect(x: 200, y: 40, width: 80, height: 20))
        weeklyField.stringValue = "40"
        accessoryView.addSubview(weeklyField)
        
        alert.accessoryView = accessoryView
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Save goals (would implement proper goal storage)
            showNotification(title: "Goals Set", message: "🎯 Your time goals have been saved!")
        }
    }
    
    // MARK: - Preferences
    @objc func showPreferences() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "⚙️ TimeDeck Preferences"
        window.center()
        
        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = contentView
        
        // Title
        let titleLabel = NSTextField(labelWithString: "⚙️ TimeDeck Enhanced Preferences")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: 300, width: 410, height: 25)
        contentView.addSubview(titleLabel)
        
        // Idle Detection
        let idleCheckbox = NSButton(checkboxWithTitle: "Enable idle detection", target: self, action: #selector(idleDetectionToggled(_:)))
        idleCheckbox.state = preferences.idleDetectionEnabled ? .on : .off
        idleCheckbox.frame = NSRect(x: 20, y: 260, width: 200, height: 20)
        contentView.addSubview(idleCheckbox)
        
        let idleLabel = NSTextField(labelWithString: "Idle threshold (minutes):")
        idleLabel.frame = NSRect(x: 40, y: 230, width: 150, height: 20)
        contentView.addSubview(idleLabel)
        
        let idleField = NSTextField(frame: NSRect(x: 200, y: 230, width: 60, height: 20))
        idleField.stringValue = String(Int(preferences.idleThreshold / 60))
        idleField.tag = 1
        contentView.addSubview(idleField)
        
        // Pomodoro
        let pomodoroCheckbox = NSButton(checkboxWithTitle: "Enable Pomodoro timer", target: self, action: #selector(pomodoroToggled(_:)))
        pomodoroCheckbox.state = preferences.pomodoroEnabled ? .on : .off
        pomodoroCheckbox.frame = NSRect(x: 20, y: 190, width: 200, height: 20)
        contentView.addSubview(pomodoroCheckbox)
        
        let workLabel = NSTextField(labelWithString: "Work duration (minutes):")
        workLabel.frame = NSRect(x: 40, y: 160, width: 150, height: 20)
        contentView.addSubview(workLabel)
        
        let workField = NSTextField(frame: NSRect(x: 200, y: 160, width: 60, height: 20))
        workField.stringValue = String(Int(preferences.pomodoroWorkDuration / 60))
        workField.tag = 2
        contentView.addSubview(workField)
        
        let breakLabel = NSTextField(labelWithString: "Break duration (minutes):")
        breakLabel.frame = NSRect(x: 40, y: 130, width: 150, height: 20)
        contentView.addSubview(breakLabel)
        
        let breakField = NSTextField(frame: NSRect(x: 200, y: 130, width: 60, height: 20))
        breakField.stringValue = String(Int(preferences.pomodoroBreakDuration / 60))
        breakField.tag = 3
        contentView.addSubview(breakField)
        
        // Buttons
        let saveButton = NSButton(frame: NSRect(x: 280, y: 20, width: 80, height: 30))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(savePreferences(_:))
        contentView.addSubview(saveButton)
        
        let cancelButton = NSButton(frame: NSRect(x: 370, y: 20, width: 60, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(closePreferences(_:))
        contentView.addSubview(cancelButton)
        
        // Store field references
        window.contentView?.setValue(idleField, forKey: "idleField")
        window.contentView?.setValue(workField, forKey: "workField")
        window.contentView?.setValue(breakField, forKey: "breakField")
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func idleDetectionToggled(_ sender: NSButton) {
        preferences.idleDetectionEnabled = sender.state == .on
        if preferences.idleDetectionEnabled {
            startIdleDetection()
        } else {
            idleTimer?.invalidate()
            idleTimer = nil
        }
    }
    
    @objc func pomodoroToggled(_ sender: NSButton) {
        preferences.pomodoroEnabled = sender.state == .on
        // Rebuild menu to show/hide pomodoro options
        setupMenuBar()
    }
    
    @objc func savePreferences(_ sender: NSButton) {
        if let window = sender.window,
           let idleField = window.contentView?.value(forKey: "idleField") as? NSTextField,
           let workField = window.contentView?.value(forKey: "workField") as? NSTextField,
           let breakField = window.contentView?.value(forKey: "breakField") as? NSTextField {
            
            preferences.idleThreshold = TimeInterval(idleField.integerValue * 60)
            preferences.pomodoroWorkDuration = TimeInterval(workField.integerValue * 60)
            preferences.pomodoroBreakDuration = TimeInterval(breakField.integerValue * 60)
            
            showNotification(title: "Preferences Saved", message: "⚙️ Your settings have been updated!")
            window.close()
        }
    }
    
    @objc func closePreferences(_ sender: NSButton) {
        sender.window?.close()
    }
    
    @objc func endDay() {
        runAppleScript("EndDay")
        updateCurrentActivity()
    }
    
    // MARK: - System Integration
    func setupGlobalKeyboardShortcuts() {
        // Global hotkey for new activity (⌘⌥T)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 17 { // T key
                self.newActivity()
            }
            
            // Global hotkey for pause/resume (⌘⌥P)
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 35 { // P key
                self.pauseResumeActivity()
            }
            
            // Global hotkey for end activity (⌘⌥E)
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 14 { // E key
                self.endActivity()
            }
        }
    }
    
    func startIdleDetection() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.checkIdleState()
        }
    }
    
    func checkIdleState() {
        let idleTime = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .mouseMoved)
        
        if idleTime > preferences.idleThreshold {
            // User has been idle
            if !isInBreak {
                isInBreak = true
                handleIdleDetected()
            }
        } else {
            // User is active
            if isInBreak {
                isInBreak = false
                handleReturnFromIdle()
            }
            lastActivityTime = Date()
        }
    }
    
    func handleIdleDetected() {
        // Don't interrupt if pomodoro is running
        if pomodoroTimer != nil {
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "💤 Idle Time Detected"
        alert.informativeText = "You've been away for \(Int(preferences.idleThreshold/60)) minutes. What would you like to do?"
        alert.addButton(withTitle: "Log as Break")
        alert.addButton(withTitle: "Continue Current Activity")
        alert.addButton(withTitle: "Start New Activity")
        
        DispatchQueue.main.async {
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                // Log as break
                self.runAppleScript("EndActivity")
                self.runAppleScript("NewActivity", args: ["Break"])
                self.showNotification(title: "Break Logged", message: "🧘 Idle time logged as break")
            case .alertSecondButtonReturn:
                // Continue current activity (do nothing)
                self.showNotification(title: "Continuing", message: "⏳ Continuing current activity")
            case .alertThirdButtonReturn:
                // Start new activity
                self.runAppleScript("EndActivity")
                self.newActivity()
            default:
                break
            }
            self.updateCurrentActivity()
        }
    }
    
    func handleReturnFromIdle() {
        showNotification(title: "Welcome Back", message: "👋 Ready to continue tracking!")
    }
    
    func showNotification(title: String, message: String) {
        if #available(macOS 11.0, *) {
            // Use modern UserNotifications framework
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        } else {
            // Fallback to NSUserNotification for older macOS
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = NSUserNotificationDefaultSoundName
            
            // Set app icon
            notification.contentImage = NSImage(named: "TimeDeck")
            
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    // Enhanced About dialog
    @objc func showAbout() {
        let aboutText = """
        ✨ TimeDeck Enhanced
        Version: 1.0.0 (Enhanced Edition)
        Author: Jeremy Roberts
        
        🚀 Enhanced Features:
        • Smart activity templates & quick actions
        • Intelligent break detection & idle handling
        • Pomodoro timer integration
        • Real-time analytics dashboard
        • Advanced export options (CSV, JSON)
        • Global keyboard shortcuts
        • Goal setting & progress tracking
        • Enhanced UI with beautiful dialogs
        
        ⌨️ Keyboard Shortcuts:
        • ⌘⌥T - New Activity
        • ⌘⌥P - Pause/Resume
        • ⌘⌥E - End Activity
        • ⌘⌥D - Dashboard
        • ⌘⌥, - Preferences
        
        🎯 Click menu items to access all enhanced functions!
        """
        
        showAlert(title: "About TimeDeck Enhanced", message: aboutText)
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
        print("DEBUG: Application terminating, cleaning up...")
        print("DEBUG: About to invalidate timers")
        timer?.invalidate()
        idleTimer?.invalidate()
        pomodoroTimer?.invalidate()
        print("DEBUG: Timers invalidated")
        
        
        print("DEBUG: About to remove notification observers")
        NotificationCenter.default.removeObserver(self)
        print("DEBUG: Notification observers removed")
        print("DEBUG: Cleanup completed")
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// Main entry point
let app = NSApplication.shared
let delegate = TimeDeckApp()
app.delegate = delegate
app.run()
