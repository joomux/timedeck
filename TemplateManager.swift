import Cocoa

// MARK: - Template Manager
class TemplateManager {
    static let shared = TemplateManager()
    private let preferences = TimeDeckPreferences.shared
    
    private init() {}
    
    // MARK: - Main Template Management Entry Point
    func showManageTemplates() {
        let response = AlertManager.shared.showAlert(
            type: .info,
            title: "🏷️ Template Management",
            message: "Choose an action for your activity templates:",
            primaryButton: "➕ Add New Template",
            secondaryButton: "📝 Manage Existing Templates"
        )
        
        switch response {
        case .alertFirstButtonReturn:
            showEnhancedAddTemplate()
        case .alertSecondButtonReturn:
            showEnhancedTemplateList()
        default:
            break
        }
    }
    
    // MARK: - Add New Template
    private func showEnhancedAddTemplate() {
        showTemplateEditor(template: nil, isEditing: false)
    }
    
    // MARK: - Manage Existing Templates
    private func showEnhancedTemplateList() {
        let templates = preferences.activityTemplates
        
        if templates.isEmpty {
            let response = AlertManager.shared.showAlert(
                type: .info,
                title: "📝 No Templates Found",
                message: "You haven't created any templates yet. Would you like to add one?",
                primaryButton: "➕ Add Template",
                secondaryButton: "Cancel"
            )
            
            if response == .alertFirstButtonReturn {
                showEnhancedAddTemplate()
            }
            return
        }
        
        // Use the new template selection UI
        guard let result = AlertManager.shared.showTemplateSelectionAlert(templates: templates) else {
            return // User cancelled
        }
        
        switch result.action {
        case .add:
            showEnhancedAddTemplate()
        case .edit:
            if let template = result.template {
                showTemplateEditor(template: template, isEditing: true)
            }
        case .delete:
            if let template = result.template,
               let index = templates.firstIndex(where: { $0.name == template.name }) {
                showDeleteTemplate(template: template, at: index)
            }
        case .start:
            if let template = result.template {
                // Start activity with this template
                ActivityTracker.shared.startActivity(name: template.name)
            }
        }
    }
    
    // MARK: - Template Editor
    private func showTemplateEditor(template: ActivityTemplate?, isEditing: Bool) {
        // Preserve the original template for editing
        let originalTemplate = template
        
        let (response, newTemplate) = AlertManager.shared.showTemplateFormAlert(isEditing: isEditing, template: template)
        
        if response == .alertFirstButtonReturn, let editedTemplate = newTemplate {
            // Save the template with the original template reference for editing
            saveTemplate(
                original: originalTemplate, // Pass the original template, not the new one
                name: editedTemplate.name,
                emoji: editedTemplate.emoji,
                category: editedTemplate.category,
                color: NSColor.systemBlue, // Default color for now
                isQuickAction: editedTemplate.isQuickAction,
                isEditing: isEditing
            )
        }
    }
    
    // MARK: - Save Template
    private func saveTemplate(original: ActivityTemplate?, name: String, emoji: String, category: String, color: NSColor, isQuickAction: Bool, isEditing: Bool) {
        var templates = preferences.activityTemplates
        print("DEBUG: saveTemplate called - isEditing: \(isEditing), original: \(original?.name ?? "nil")")
        print("DEBUG: Current templates count: \(templates.count)")
        
        let newTemplate = ActivityTemplate(
            name: name,
            color: color,
            emoji: emoji,
            category: category,
            isQuickAction: isQuickAction
        )
        
        if isEditing, let originalTemplate = original {
            // Find and replace the original template
            print("DEBUG: Looking for template to edit: '\(originalTemplate.name)' with emoji '\(originalTemplate.emoji)' category '\(originalTemplate.category)'")
            
            // Use a more robust comparison that doesn't rely on NSColor equality
            var foundIndex: Int? = nil
            for (index, template) in templates.enumerated() {
                let nameMatch = template.name == originalTemplate.name
                let emojiMatch = template.emoji == originalTemplate.emoji
                let categoryMatch = template.category == originalTemplate.category
                let quickMatch = template.isQuickAction == originalTemplate.isQuickAction
                
                print("DEBUG: Checking template \(index): '\(template.name)' - name:\(nameMatch) emoji:\(emojiMatch) category:\(categoryMatch) quick:\(quickMatch)")
                
                if nameMatch && emojiMatch && categoryMatch && quickMatch {
                    foundIndex = index
                    break
                }
            }
            
            if let index = foundIndex {
                print("DEBUG: Found template at index \(index), replacing with new template '\(newTemplate.name)'")
                templates[index] = newTemplate
            } else {
                print("DEBUG: ERROR - Could not find original template to replace!")
                print("DEBUG: Looking for: name='\(originalTemplate.name)' emoji='\(originalTemplate.emoji)' category='\(originalTemplate.category)' quick=\(originalTemplate.isQuickAction)")
                for (i, t) in templates.enumerated() {
                    print("DEBUG:   Template \(i): name='\(t.name)' emoji='\(t.emoji)' category='\(t.category)' quick=\(t.isQuickAction)")
                }
                // Add as new template instead of failing silently
                templates.append(newTemplate)
                print("DEBUG: Added as new template instead")
            }
        } else {
            // Add new template
            print("DEBUG: Adding new template '\(newTemplate.name)'")
            templates.append(newTemplate)
        }
        
        preferences.activityTemplates = templates
        print("DEBUG: Templates saved, new count: \(templates.count)")
        
        // Verify the save worked by reading back from preferences
        let savedTemplates = preferences.activityTemplates
        print("DEBUG: Verification - read back \(savedTemplates.count) templates from preferences")
        if let savedTemplate = savedTemplates.first(where: { $0.name == newTemplate.name }) {
            print("DEBUG: Verification - found saved template: '\(savedTemplate.name)' emoji '\(savedTemplate.emoji)'")
        } else {
            print("DEBUG: ERROR - Could not find the saved template when reading back!")
        }
        
        // Post notification that templates were updated
        NotificationCenter.default.post(name: NSNotification.Name("TemplatesUpdated"), object: nil)
        
        AlertManager.shared.showAlert(
            type: .success,
            title: isEditing ? "✅ Template Updated" : "✅ Template Created",
            message: "'\(emoji) \(name)' has been \(isEditing ? "updated" : "added to your templates")."
        )
    }
    
    // MARK: - Delete Template
    private func showDeleteTemplate(template: ActivityTemplate, at index: Int) {
        let confirmed = AlertManager.shared.showConfirmationAlert(
            title: "🗑️ Delete Template",
            message: "Are you sure you want to delete '\(template.emoji) \(template.name)'?\n\nThis action cannot be undone.",
            confirmText: "🗑️ Delete",
            cancelText: "❌ Cancel"
        )
        
        if confirmed {
            var templates = preferences.activityTemplates
            templates.remove(at: index)
            preferences.activityTemplates = templates
            
            AlertManager.shared.showAlert(
                type: .success,
                title: "✅ Template Deleted",
                message: "'\(template.emoji) \(template.name)' has been removed from your templates."
            )
            
            // Return to template list if there are still templates
            if !templates.isEmpty {
                showEnhancedTemplateList()
            }
        } else {
            // Return to template list
            showEnhancedTemplateList()
        }
    }
}
