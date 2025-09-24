import Cocoa

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

// MARK: - Idle State
enum IdleState {
    case active     // User is actively working
    case idle       // User has been detected as idle
    case returning  // Return dialog is shown, waiting for user response
}

// MARK: - Preferences Manager
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
            print("DEBUG: TimeDeckPreferences.activityTemplates setter called with \(newValue.count) templates")
            do {
                let templateData: [ActivityTemplateData] = newValue.compactMap { template in
                    let safeColor: NSColor
                    if let rgbColor = template.color.usingColorSpace(.deviceRGB) {
                        safeColor = rgbColor
                    } else {
                        safeColor = NSColor.systemBlue
                    }
                    
                    guard let colorData = try? NSKeyedArchiver.archivedData(withRootObject: safeColor, requiringSecureCoding: false) else {
                        print("DEBUG: Failed to archive color data for template: \(template.name)")
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
                
                print("DEBUG: Successfully created \(templateData.count) ActivityTemplateData objects")
                let data = try JSONEncoder().encode(templateData)
                print("DEBUG: Successfully encoded template data, size: \(data.count) bytes")
                userDefaults.set(data, forKey: "activityTemplates")
                print("DEBUG: Set data to UserDefaults")
                userDefaults.synchronize()
                print("DEBUG: Synchronized UserDefaults")
                
                // Notify to rebuild menu
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("TemplatesUpdated"), object: nil)
                }
                print("DEBUG: Posted TemplatesUpdated notification")
            } catch {
                print("DEBUG: Error saving templates: \(error)")
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
    
    // Idle timeout in minutes (default: 5 minutes)
    var idleTimeoutMinutes: Int {
        get { 
            let value = userDefaults.integer(forKey: "idleTimeoutMinutes")
            return value > 0 ? value : 5  // Default to 5 minutes
        }
        set { userDefaults.set(newValue, forKey: "idleTimeoutMinutes") }
    }
    
    // Auto-end timeout in minutes after showing return dialog (default: 60 minutes)
    var autoEndTimeoutMinutes: Int {
        get {
            let value = userDefaults.integer(forKey: "autoEndTimeoutMinutes")
            return value > 0 ? value : 60  // Default to 60 minutes
        }
        set { userDefaults.set(newValue, forKey: "autoEndTimeoutMinutes") }
    }
    
}
