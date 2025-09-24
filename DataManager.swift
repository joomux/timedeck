import Foundation

// MARK: - Activity Log Entry Structure
struct ActivityLogEntry: Codable {
    let timestamp: Date
    let action: ActivityAction
    let activityName: String?
    let duration: TimeInterval?
    let metadata: [String: String]?
    
    enum ActivityAction: String, Codable {
        case start = "START"
        case quickStart = "QUICK_START"
        case end = "END"
        case pause = "PAUSE"
        case resume = "RESUME"
        case dayEnd = "DAY_END"
        case freshStart = "FRESH_START"
        case idleDetected = "IDLE_DETECTED"
        case returnFromIdle = "RETURN_FROM_IDLE"
    }
    
    init(action: ActivityAction, activityName: String? = nil, duration: TimeInterval? = nil, metadata: [String: String]? = nil) {
        self.timestamp = Date()
        self.action = action
        self.activityName = activityName
        self.duration = duration
        self.metadata = metadata
    }
}

// MARK: - Daily Activity Log
struct DailyActivityLog: Codable {
    let date: String // YYYY-MM-DD format
    var entries: [ActivityLogEntry]
    let version: String = "1.0"
    
    init(date: String) {
        self.date = date
        self.entries = []
    }
}

// MARK: - Data Manager
class DataManager {
    static let shared = DataManager()
    
    // Enhanced storage location
    private let baseDirectory: URL
    private let logsDirectory: URL
    private let backupDirectory: URL
    private let exportDirectory: URL
    
    private let dateFormatter: DateFormatter
    private let fileManager = FileManager.default
    
    private init() {
        // Create proper app support directory structure
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        baseDirectory = appSupport.appendingPathComponent("TimeDeck")
        logsDirectory = baseDirectory.appendingPathComponent("Logs")
        backupDirectory = baseDirectory.appendingPathComponent("Backups")
        exportDirectory = baseDirectory.appendingPathComponent("Exports")
        
        // Date formatter for file names
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Create directories if needed
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        let directories = [baseDirectory, logsDirectory, backupDirectory, exportDirectory]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }
    
    // MARK: - Logging Methods
    func logActivity(_ action: ActivityLogEntry.ActivityAction, activityName: String? = nil, duration: TimeInterval? = nil, metadata: [String: String]? = nil) {
        let entry = ActivityLogEntry(action: action, activityName: activityName, duration: duration, metadata: metadata)
        
        // Get today's log file
        let today = dateFormatter.string(from: Date())
        var dailyLog = loadDailyLog(for: today)
        
        // Add entry
        dailyLog.entries.append(entry)
        
        // Save back to file
        saveDailyLog(dailyLog)
        
        print("📝 Logged: \(action.rawValue) \(activityName ?? "")")
    }
    
    private func loadDailyLog(for date: String) -> DailyActivityLog {
        let fileURL = logsDirectory.appendingPathComponent("\(date).json")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(DailyActivityLog.self, from: data)
            } catch {
                print("⚠️ Error loading daily log: \(error)")
                // Create new log if corrupted
                return DailyActivityLog(date: date)
            }
        } else {
            // Create new daily log
            return DailyActivityLog(date: date)
        }
    }
    
    private func saveDailyLog(_ dailyLog: DailyActivityLog) {
        let fileURL = logsDirectory.appendingPathComponent("\(dailyLog.date).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(dailyLog)
            try data.write(to: fileURL)
        } catch {
            print("❌ Error saving daily log: \(error)")
        }
    }
    
    // MARK: - Data Retrieval
    func getTodaysEntries() -> [ActivityLogEntry] {
        let today = dateFormatter.string(from: Date())
        return loadDailyLog(for: today).entries
    }
    
    func getEntriesForDate(_ date: Date) -> [ActivityLogEntry] {
        let dateString = dateFormatter.string(from: date)
        return loadDailyLog(for: dateString).entries
    }
    
    func getEntriesForDateRange(_ startDate: Date, _ endDate: Date) -> [ActivityLogEntry] {
        var allEntries: [ActivityLogEntry] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let entries = getEntriesForDate(currentDate)
            allEntries.append(contentsOf: entries)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return allEntries.sorted { $0.timestamp < $1.timestamp }
    }
    
    func getRecentActivities(limit: Int) -> [String] {
        let todaysEntries = getTodaysEntries()
        var activities: [String] = []
        
        // Get unique activity names from recent START/QUICK_START entries
        for entry in todaysEntries.reversed() {
            if (entry.action == .start || entry.action == .quickStart),
               let activityName = entry.activityName,
               !activities.contains(activityName) {
                activities.append(activityName)
                if activities.count >= limit { break }
            }
        }
        
        return activities
    }
    
    // MARK: - Analytics
    func getDailyStats(for date: Date) -> (totalTime: TimeInterval, activities: [String: TimeInterval]) {
        let entries = getEntriesForDate(date)
        var totalTime: TimeInterval = 0
        var activities: [String: TimeInterval] = [:]
        
        var currentActivity: String?
        var currentStartTime: Date?
        
        for entry in entries {
            switch entry.action {
            case .start, .quickStart, .resume:
                currentActivity = entry.activityName
                currentStartTime = entry.timestamp
                
            case .end, .pause:
                if let activity = currentActivity,
                   let startTime = currentStartTime {
                    let duration = entry.timestamp.timeIntervalSince(startTime)
                    totalTime += duration
                    activities[activity] = (activities[activity] ?? 0) + duration
                }
                if entry.action == .end {
                    currentActivity = nil
                    currentStartTime = nil
                }
            default:
                break
            }
        }
        
        return (totalTime, activities)
    }
    
    // MARK: - Export Functions
    func exportToCSV(startDate: Date, endDate: Date) -> URL? {
        let entries = getEntriesForDateRange(startDate, endDate)
        
        // Create timesheet-friendly CSV format
        var csvContent = "Start Date/Time,Duration (HH:mm),Activity\n"
        
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Process entries to extract completed activity sessions
        var activities: [(startTime: Date, duration: TimeInterval, activity: String)] = []
        var currentActivity: String?
        var currentStartTime: Date?
        
        for entry in entries {
            switch entry.action {
            case .start, .quickStart:
                if let activity = entry.activityName {
                    currentActivity = activity
                    currentStartTime = entry.timestamp
                }
            case .end:
                if let activity = currentActivity,
                   let startTime = currentStartTime {
                    let duration = entry.timestamp.timeIntervalSince(startTime)
                    activities.append((startTime: startTime, duration: duration, activity: activity))
                }
                currentActivity = nil
                currentStartTime = nil
            case .pause, .resume, .dayEnd, .freshStart, .idleDetected, .returnFromIdle:
                // For timesheet export, we'll ignore these actions as they don't represent activity sessions
                break
            }
        }
        
        // If there's an ongoing activity, include it with duration up to now
        if let activity = currentActivity,
           let startTime = currentStartTime {
            let duration = Date().timeIntervalSince(startTime)
            activities.append((startTime: startTime, duration: duration, activity: activity))
        }
        
        // Write activity sessions to CSV
        for activity in activities {
            let startDateTime = dateTimeFormatter.string(from: activity.startTime)
            let durationHHMM = formatDurationAsHHMM(activity.duration)
            let activityName = activity.activity.replacingOccurrences(of: ",", with: ";") // Escape commas
            
            csvContent += "\(startDateTime),\(durationHHMM),\(activityName)\n"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "timedeck_timesheet_\(dateFormatter.string(from: startDate))_to_\(dateFormatter.string(from: endDate)).csv"
        let exportURL = exportDirectory.appendingPathComponent(filename)
        
        do {
            try csvContent.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            print("❌ Export error: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Functions
    private func formatDurationAsHHMM(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    // MARK: - Data Management
    func clearAllData() {
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
            for file in logFiles {
                try fileManager.removeItem(at: file)
            }
            print("🧹 All activity logs cleared")
        } catch {
            print("❌ Error clearing logs: \(error)")
        }
    }
    
    func backupData() {
        let timestamp = DateFormatter().string(from: Date())
        let backupURL = backupDirectory.appendingPathComponent("backup_\(timestamp)")
        
        do {
            try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true, attributes: nil)
            
            let logFiles = try fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
            for file in logFiles {
                let destinationURL = backupURL.appendingPathComponent(file.lastPathComponent)
                try fileManager.copyItem(at: file, to: destinationURL)
            }
            
            print("💾 Data backed up to: \(backupURL.path)")
        } catch {
            print("❌ Backup error: \(error)")
        }
    }
    
    // MARK: - File System Info
    var dataDirectoryPath: String {
        return baseDirectory.path
    }
    
    var currentLogFilePath: String {
        let today = dateFormatter.string(from: Date())
        return logsDirectory.appendingPathComponent("\(today).json").path
    }
    
    func getDataSizeInfo() -> (totalFiles: Int, totalSize: String) {
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0
            
            for file in logFiles {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
            
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            
            return (logFiles.count, formatter.string(fromByteCount: totalSize))
        } catch {
            return (0, "Unknown")
        }
    }
}
