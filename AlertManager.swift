import Cocoa

// MARK: - Enhanced Alert System
class AlertManager: NSObject {
    static let shared = AlertManager()
    private override init() {}
    
    // Simple property to track radio button selection
    private var currentTemplateSelectionIndex: Int = 0
    
    // MARK: - Alert Types
    enum AlertType {
        case info
        case success
        case warning
        case error
        case question
    }
    
    // MARK: - Simple Alerts
    @discardableResult
    func showAlert(
        type: AlertType,
        title: String,
        message: String,
        primaryButton: String = "OK",
        secondaryButton: String? = nil
    ) -> NSApplication.ModalResponse {
        
        let alert = createStyledAlert(type: type, title: title)
        alert.informativeText = formatMessage(message)
        
        alert.addButton(withTitle: primaryButton)
        if let secondary = secondaryButton {
            alert.addButton(withTitle: secondary)
        }
        
        return alert.runModal()
    }
    
    // MARK: - Status Alert (for activity info)
    func showStatusAlert(title: String, activity: String?, timeString: String?) {
        let alert = createStyledAlert(type: .info, title: title)
        
        if let activity = activity, let time = timeString {
            alert.informativeText = formatActivityStatus(activity: activity, time: time)
        } else {
            alert.informativeText = "No active activity being tracked"
        }
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - List Alert (for templates, recent activities)
    func showListAlert(
        title: String,
        subtitle: String,
        items: [String],
        buttons: [String],
        allowsInput: Bool = false,
        inputPlaceholder: String = ""
    ) -> (response: NSApplication.ModalResponse, inputText: String?) {
        
        let alert = createStyledAlert(type: .info, title: title)
        
        // Create formatted list content
        let formattedContent = formatListContent(subtitle: subtitle, items: items)
        alert.informativeText = formattedContent
        
        var inputField: NSTextField?
        
        // Add input field if needed
        if allowsInput {
            let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 50))
            
            let inputLabel = NSTextField(labelWithString: inputPlaceholder)
            inputLabel.frame = NSRect(x: 0, y: 25, width: 400, height: 20)
            inputLabel.font = NSFont.systemFont(ofSize: 12)
            inputLabel.textColor = .secondaryLabelColor
            
            let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
            field.placeholderString = inputPlaceholder
            field.font = NSFont.systemFont(ofSize: 13)
            
            accessoryView.addSubview(inputLabel)
            accessoryView.addSubview(field)
            alert.accessoryView = accessoryView
            inputField = field
        }
        
        // Add buttons
        for button in buttons {
            alert.addButton(withTitle: button)
        }
        
        let response = alert.runModal()
        return (response, inputField?.stringValue)
    }
    
    // MARK: - Report Alert (for generated reports)
    func showReportAlert(title: String, filePath: String) {
        let alert = createStyledAlert(type: .success, title: title)
        
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        let directory = URL(fileURLWithPath: filePath).deletingLastPathComponent().path
        
        alert.informativeText = formatReportInfo(fileName: fileName, directory: directory)
        
        alert.addButton(withTitle: "📖 Open Report")
        alert.addButton(withTitle: "📁 Show in Finder")
        alert.addButton(withTitle: "✅ OK")
        
        let response = alert.runModal()
        let reportURL = URL(fileURLWithPath: filePath)
        
        switch response {
        case .alertFirstButtonReturn:
            NSWorkspace.shared.open(reportURL)
        case .alertSecondButtonReturn:
            NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: directory)
        default:
            break
        }
    }
    
    // MARK: - Dashboard Alert (for analytics)
    func showDashboardAlert(todayData: String, weekData: String) {
        let alert = createStyledAlert(type: .info, title: "📊 Activity Dashboard")
        alert.informativeText = formatDashboardContent(todayData: todayData, weekData: weekData)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Template Form Alert
    func showTemplateFormAlert(
        isEditing: Bool,
        template: ActivityTemplate? = nil
    ) -> (response: NSApplication.ModalResponse, template: ActivityTemplate?) {
        
        let alert = createStyledAlert(type: .info, title: isEditing ? "✏️ Edit Template" : "➕ Add New Template")
        alert.informativeText = isEditing ? "Modify the template details below:" : "Enter the details for your new template:"
        
        // Create form view
        let formView = createTemplateFormView(template: template)
        alert.accessoryView = formView
        
        alert.addButton(withTitle: isEditing ? "💾 Save Changes" : "➕ Create Template")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Extract form data
            if let extractedTemplate = extractTemplateFromForm(formView: formView) {
                return (response, extractedTemplate)
            }
        }
        
        return (response, nil)
    }
    
    // MARK: - Confirmation Alert
    func showConfirmationAlert(title: String, message: String, confirmText: String = "Confirm", cancelText: String = "Cancel") -> Bool {
        let alert = createStyledAlert(type: .warning, title: title)
        alert.informativeText = formatMessage(message)
        
        alert.addButton(withTitle: confirmText)
        alert.addButton(withTitle: cancelText)
        
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    // MARK: - Template Selection Alert
    func showTemplateSelectionAlert(templates: [ActivityTemplate]) -> (action: TemplateAction, template: ActivityTemplate?)? {
        guard !templates.isEmpty else { return nil }
        
        let alert = createStyledAlert(type: .info, title: "📝 Template Management")
        alert.informativeText = "Select a template to manage:"
        
        // Create radio button selection view
        let selectionView = createTemplateRadioView(templates: templates)
        alert.accessoryView = selectionView
        
        // Add action buttons
        alert.addButton(withTitle: "✏️ Edit")
        alert.addButton(withTitle: "🗑️ Delete")
        alert.addButton(withTitle: "🚀 Start")
        alert.addButton(withTitle: "➕ Add New")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        
        // Get selected template index
        let selectedIndex = getSelectedRadioIndex(from: selectionView)
        print("DEBUG: Selected radio index: \(selectedIndex)")
        let selectedTemplate = selectedIndex >= 0 && selectedIndex < templates.count ? templates[selectedIndex] : nil
        print("DEBUG: Selected template: \(selectedTemplate?.name ?? "nil")")
        
        switch response {
        case .alertFirstButtonReturn: // Edit
            print("DEBUG: Edit button clicked, selectedTemplate: \(selectedTemplate?.name ?? "nil")")
            if let template = selectedTemplate {
                return (.edit, template)
            } else {
                print("DEBUG: No template selected, dismissing")
                showAlert(type: .error, title: "❌ No Selection", message: "Please select a template first.", primaryButton: "OK")
                return nil
            }
        case .alertSecondButtonReturn: // Delete
            print("DEBUG: Delete button clicked")
            if let template = selectedTemplate {
                return (.delete, template)
            } else {
                showAlert(type: .error, title: "❌ No Selection", message: "Please select a template first.", primaryButton: "OK")
                return nil
            }
        case .alertThirdButtonReturn: // Start
            print("DEBUG: Start button clicked")
            if let template = selectedTemplate {
                return (.start, template)
            } else {
                showAlert(type: .error, title: "❌ No Selection", message: "Please select a template first.", primaryButton: "OK")
                return nil
            }
        case NSApplication.ModalResponse(rawValue: NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + 3): // Add New
            print("DEBUG: Add New button clicked")
            return (.add, nil)
        default:
            print("DEBUG: Cancel or other button clicked")
            return nil
        }
    }
    
    private func createTemplateRadioView(templates: [ActivityTemplate]) -> NSView {
        // Main container - fixed height regardless of template count
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 250))
        
        // Reset selection to first template
        currentTemplateSelectionIndex = 0
        
        // Create scroll view for templates
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: 10, width: 380, height: 230))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .lineBorder
        
        // Calculate content height based on number of templates
        let contentHeight = max(230, templates.count * 25 + 10)
        let documentView = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: contentHeight))
        
        var radioButtons: [NSButton] = []
        var yPosition = contentHeight - 30  // Start from top of content
        
        // Create radio buttons for each template
        for (index, template) in templates.enumerated() {
            let radioButton = NSButton(frame: NSRect(x: 10, y: yPosition, width: 340, height: 20))
            radioButton.setButtonType(.radio)
            radioButton.tag = index
            
            let quickIndicator = template.isQuickAction ? " ⚡" : ""
            radioButton.title = "\(template.emoji) \(template.name) (\(template.category))\(quickIndicator)"
            radioButton.font = NSFont.systemFont(ofSize: 13)
            
            // Set first button as selected by default
            if index == 0 {
                radioButton.state = .on
            }
            
            // Add click handler
            radioButton.target = self
            radioButton.action = #selector(radioButtonClicked(_:))
            
            documentView.addSubview(radioButton)
            radioButtons.append(radioButton)
            
            yPosition -= 25
        }
        
        // Set up scroll view
        scrollView.documentView = documentView
        containerView.addSubview(scrollView)
        
        // If content fits, scroll to top. If not, ensure first item is visible
        if templates.count <= 9 {  // 9 items fit in 230px height
            scrollView.scroll(NSPoint(x: 0, y: contentHeight))
        } else {
            // Scroll to show the first few items
            scrollView.scroll(NSPoint(x: 0, y: contentHeight - 230))
        }
        
        print("DEBUG: Created \(radioButtons.count) radio buttons in scrollable view, selection index set to: \(currentTemplateSelectionIndex)")
        
        return containerView
    }
    
    @objc private func radioButtonClicked(_ sender: NSButton) {
        print("DEBUG: Radio button clicked with tag: \(sender.tag)")
        
        // Update our selection index
        currentTemplateSelectionIndex = sender.tag
        print("DEBUG: Updated currentTemplateSelectionIndex to: \(currentTemplateSelectionIndex)")
        
        // Get the container and deselect other radio buttons
        guard let containerView = sender.superview else {
            print("DEBUG: No container view found")
            return
        }
        
        // Deselect all radio buttons in the container
        for subview in containerView.subviews {
            if let radioButton = subview as? NSButton {
                radioButton.state = .off
            }
        }
        
        // Select the clicked button
        sender.state = .on
        print("DEBUG: Radio button selection updated successfully")
    }
    
    private func getSelectedRadioIndex(from containerView: NSView) -> Int {
        print("DEBUG: Getting selected radio index...")
        print("DEBUG: Returning currentTemplateSelectionIndex: \(currentTemplateSelectionIndex)")
        return currentTemplateSelectionIndex
    }
    
    
    
    private func showTemplateActionAlert(for template: ActivityTemplate) -> (action: TemplateAction, template: ActivityTemplate?)? {
        let alert = createStyledAlert(type: .question, title: "📝 \(template.emoji) \(template.name)")
        alert.informativeText = """
        Category: \(template.category)
        Quick Action: \(template.isQuickAction ? "Yes ⚡" : "No")
        
        What would you like to do with this template?
        """
        
        alert.addButton(withTitle: "✏️ Edit Template")
        alert.addButton(withTitle: "🗑️ Delete Template")
        alert.addButton(withTitle: "🚀 Start Activity")
        alert.addButton(withTitle: "❌ Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            return (.edit, template)
        case .alertSecondButtonReturn:
            return (.delete, template)
        case .alertThirdButtonReturn:
            return (.start, template)
        default:
            return nil
        }
    }
    
    enum TemplateAction {
        case add
        case edit
        case delete
        case start
    }
    
    // MARK: - Private Helper Methods
    
    private func createStyledAlert(type: AlertType, title: String) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title
        
        // Set alert style and icon based on type
        switch type {
        case .info:
            alert.alertStyle = .informational
        case .success:
            alert.alertStyle = .informational
        case .warning:
            alert.alertStyle = .warning
        case .error:
            alert.alertStyle = .critical
        case .question:
            alert.alertStyle = .warning
        }
        
        return alert
    }
    
    private func formatMessage(_ message: String) -> String {
        // For multi-line messages, ensure proper formatting
        return message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatActivityStatus(activity: String, time: String) -> String {
        return """
        Current Activity:  \(activity)
        Elapsed Time:      \(time)
        
        Status: Active and tracking
        """
    }
    
    private func formatListContent(subtitle: String, items: [String]) -> String {
        var content = subtitle
        
        if !items.isEmpty {
            content += "\n\n"
            for (index, item) in items.enumerated() {
                content += "\(index + 1). \(item)\n"
            }
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return content
    }
    
    private func formatReportInfo(fileName: String, directory: String) -> String {
        return """
        Report successfully generated!
        
        File: \(fileName)
        Location: \(directory)
        
        Choose how you'd like to view the report:
        """
    }
    
    private func formatDashboardContent(todayData: String, weekData: String) -> String {
        return """
        📅 TODAY'S SUMMARY:
        \(todayData)
        
        📊 WEEKLY OVERVIEW:
        \(weekData)
        
        Keep up the great work! 🎯
        """
    }
    
    private func createTemplateFormView(template: ActivityTemplate?) -> NSView {
        let formView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        
        var yPos = 175
        
        // Name field
        let nameLabel = createFormLabel(text: "Name:", yPos: yPos)
        let nameField = createFormField(placeholder: "Enter activity name", yPos: yPos - 25)
        nameField.tag = 1001
        if let template = template {
            nameField.stringValue = template.name
        }
        
        // Emoji field
        yPos -= 55
        let emojiLabel = createFormLabel(text: "Emoji:", yPos: yPos)
        let emojiField = createFormField(placeholder: "🎯", yPos: yPos - 25)
        emojiField.tag = 1002
        if let template = template {
            emojiField.stringValue = template.emoji
        }
        
        // Category field
        yPos -= 55
        let categoryLabel = createFormLabel(text: "Category:", yPos: yPos)
        let categoryCombo = NSComboBox(frame: NSRect(x: 100, y: yPos - 25, width: 280, height: 24))
        categoryCombo.addItems(withObjectValues: ["Work", "Personal", "Learning", "Health", "Creative", "Social"])
        categoryCombo.tag = 1003
        if let template = template {
            categoryCombo.stringValue = template.category
        } else {
            categoryCombo.stringValue = "Work"
        }
        
        // Quick action checkbox
        yPos -= 55
        let quickCheckbox = NSButton(checkboxWithTitle: "⚡ Quick Action (show in menu)", target: nil, action: nil)
        quickCheckbox.frame = NSRect(x: 100, y: yPos, width: 280, height: 20)
        quickCheckbox.tag = 1004
        if let template = template {
            quickCheckbox.state = template.isQuickAction ? .on : .off
        }
        
        // Add all controls
        [nameLabel, nameField, emojiLabel, emojiField, categoryLabel, categoryCombo, quickCheckbox].forEach {
            formView.addSubview($0)
        }
        
        return formView
    }
    
    private func createFormLabel(text: String, yPos: Int) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: 0, y: yPos, width: 90, height: 20)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.alignment = .right
        return label
    }
    
    private func createFormField(placeholder: String, yPos: Int) -> NSTextField {
        let field = NSTextField(frame: NSRect(x: 100, y: yPos, width: 280, height: 24))
        field.placeholderString = placeholder
        field.font = NSFont.systemFont(ofSize: 13)
        return field
    }
    
    private func extractTemplateFromForm(formView: NSView) -> ActivityTemplate? {
        guard let nameField = formView.viewWithTag(1001) as? NSTextField,
              let emojiField = formView.viewWithTag(1002) as? NSTextField,
              let categoryCombo = formView.viewWithTag(1003) as? NSComboBox,
              let quickCheckbox = formView.viewWithTag(1004) as? NSButton else {
            return nil
        }
        
        let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = emojiField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = categoryCombo.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty, !emoji.isEmpty, !category.isEmpty else {
            AlertManager.shared.showAlert(
                type: .error,
                title: "❌ Invalid Input",
                message: "Please fill in all required fields:\n• Name\n• Emoji\n• Category"
            )
            return nil
        }
        
        return ActivityTemplate(
            name: name,
            color: NSColor.systemBlue, // Default blue
            emoji: emoji,
            category: category,
            isQuickAction: quickCheckbox.state == .on
        )
    }
}

