import Cocoa
import UniformTypeIdentifiers

// MARK: - Analytics Manager
class Analytics {
    static let shared = Analytics()
    
    private let dataManager = DataManager.shared
    
    private init() {}
    
    // MARK: - Dashboard
    func showDashboard() {
        let todayData = getTodayActivityData()
        let weekData = getWeekActivityData()
        
        AlertManager.shared.showDashboardAlert(todayData: todayData, weekData: weekData)
    }
    
    // MARK: - End Day Summary
    func showEndDaySummary() {
        let (totalTime, activities) = dataManager.getDailyStats(for: Date())
        
        // Check if there's any data for today
        guard totalTime > 0 || !activities.isEmpty else {
            AlertManager.shared.showAlert(
                type: .info,
                title: "🌅 End of Day",
                message: "No activities were tracked today.\n\nGreat work today! See you tomorrow! 👋"
            )
            return
        }
        
        // Format the summary content
        let summaryContent = formatEndDaySummary(totalTime: totalTime, activities: activities)
        
        // Show the summary alert
        AlertManager.shared.showEndDaySummaryAlert(summaryContent: summaryContent)
    }
    
    private func formatEndDaySummary(totalTime: TimeInterval, activities: [String: TimeInterval]) -> String {
        var content = "Today's Activity Summary:\n\n"
        
        // Sort activities by duration (most to least)
        let sortedActivities = activities.sorted { $0.value > $1.value }
        
        // Add each activity with its duration
        for (activity, duration) in sortedActivities {
            let hours = Int(duration) / 3600
            let minutes = Int(duration) % 3600 / 60
            let seconds = Int(duration) % 60
            
            if hours > 0 {
                content += "• \(activity): \(hours)h \(minutes)m\n"
            } else if minutes > 0 {
                content += "• \(activity): \(minutes)m \(seconds)s\n"
            } else {
                content += "• \(activity): \(seconds)s\n"
            }
        }
        
        // Add total time
        let totalHours = Int(totalTime) / 3600
        let totalMinutes = Int(totalTime) % 3600 / 60
        let totalSeconds = Int(totalTime) % 60
        
        content += "\n" + String(repeating: "─", count: 40) + "\n"
        
        if totalHours > 0 {
            content += "Total tracked time: \(totalHours)h \(totalMinutes)m"
        } else if totalMinutes > 0 {
            content += "Total tracked time: \(totalMinutes)m \(totalSeconds)s"
        } else {
            content += "Total tracked time: \(totalSeconds)s"
        }
        
        content += "\n\nGreat work today! 🎯"
        
        return content
    }
    
    private func getTodayActivityData() -> String {
        let (totalTime, activities) = dataManager.getDailyStats(for: Date())
        
        guard totalTime > 0 else {
            return "• No activities tracked today"
        }
        
        let totalHours = totalTime / 3600
        var result = ""
        
        // Show top activities
        let sortedActivities = activities.sorted { $0.value > $1.value }
        for (activity, duration) in sortedActivities.prefix(3) {
            let hours = duration / 3600
            result += "• \(activity): \(String(format: "%.1f", hours))h\n"
        }
        
        result += "• Total: \(String(format: "%.1f", totalHours))h"
        return result
    }
    
    private func getWeekActivityData() -> String {
        // Calculate week data from daily stats
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var weeklyTotal: TimeInterval = 0
        var dailyTotals: [TimeInterval] = []
        
        for dayOffset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                let (dayTotal, _) = dataManager.getDailyStats(for: day)
                weeklyTotal += dayTotal
                if dayTotal > 0 {
                    dailyTotals.append(dayTotal)
                }
            }
        }
        
        let weeklyHours = weeklyTotal / 3600
        let avgHours = dailyTotals.isEmpty ? 0 : (weeklyTotal / TimeInterval(dailyTotals.count)) / 3600
        let mostActiveHours = dailyTotals.max() ?? 0
        
        return """
        • Total tracked: \(String(format: "%.1f", weeklyHours))h
        • Active days: \(dailyTotals.count)
        • Avg per active day: \(String(format: "%.1f", avgHours))h
        • Best day: \(String(format: "%.1f", mostActiveHours / 3600))h
        """
    }
    
    // MARK: - Data Export
    func showExportDialog() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Activity Data"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        savePanel.nameFieldStringValue = "timedeck_export_\(dateFormatter.string(from: Date()))"
        
        if #available(macOS 12.0, *) {
            savePanel.allowedContentTypes = [UTType.commaSeparatedText, UTType.json]
        } else {
            savePanel.allowedFileTypes = ["csv", "json"]
        }
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            exportData(to: url)
        }
    }
    
    private func exportData(to url: URL) {
        // Use DataManager's built-in CSV export
        if url.pathExtension.lowercased() == "csv" {
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
            
            if let exportURL = dataManager.exportToCSV(startDate: startDate, endDate: endDate) {
                do {
                    let exportedContent = try String(contentsOf: exportURL, encoding: .utf8)
                    try exportedContent.write(to: url, atomically: true, encoding: .utf8)
                    
                    AlertManager.shared.showAlert(
                        type: .success,
                        title: "✅ Export Complete",
                        message: "Activity data exported to \(url.lastPathComponent)"
                    )
                } catch {
                    showExportError(error.localizedDescription)
                }
            } else {
                showExportError("Failed to generate CSV export")
            }
        } else {
            // For JSON export, get entries and convert
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
            let entries = dataManager.getEntriesForDateRange(startDate, endDate)
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(entries)
                try jsonData.write(to: url)
                
                AlertManager.shared.showAlert(
                    type: .success,
                    title: "✅ Export Complete",
                    message: "Activity data exported to \(url.lastPathComponent)"
                )
            } catch {
                showExportError(error.localizedDescription)
            }
        }
    }
    
    private func showExportError(_ message: String) {
        AlertManager.shared.showAlert(
            type: .error,
            title: "❌ Export Failed",
            message: message
        )
    }
    
    
    // MARK: - Reports
    func generateReport() {
        generateNativeReport()
    }
    
    private func generateNativeReport() {
        // Get last 30 days of data
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let entries = dataManager.getEntriesForDateRange(startDate, endDate)
        
        guard !entries.isEmpty else {
            showAlert(title: "📄 No Data", message: "No activity data found. Start tracking activities first!")
            return
        }
        
        let reportContent = generateReportFromEntries(entries)
        
        // Save to DataManager's export directory  
        let exportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TimeDeck")
            .appendingPathComponent("Exports")
        
        // Ensure the export directory exists
        do {
            try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            showAlert(title: "❌ Report Error", message: "Failed to create export directory: \(error.localizedDescription)")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timestamp = dateFormatter.string(from: Date())
        let reportFile = exportDir.appendingPathComponent("timedeck_report_\(timestamp).txt")
        
        do {
            try reportContent.write(to: reportFile, atomically: true, encoding: .utf8)
            
            AlertManager.shared.showReportAlert(title: "📊 Report Generated!", filePath: reportFile.path)
        } catch {
            showAlert(title: "❌ Report Error", message: "Failed to save report: \(error.localizedDescription)")
        }
    }
    
    private func processLogIntoReport(logContent: String) -> String {
        let lines = logContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var report = """
        HACKTIVITY DETAILED REPORT
        Generated: \(DateFormatter.shortDate.string(from: Date())) \(DateFormatter.shortTime.string(from: Date()))
        ================================================================================
        
        """
        
        // Group activities by date
        var activitiesByDate: [String: [(time: String, activity: String, action: String)]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for line in lines {
            let parts = line.components(separatedBy: ": ")
            guard parts.count >= 3 else { continue }
            
            let timestamp = parts[0]
            let action = parts[1]
            let activity = parts[2]
            
            if let date = dateFormatter.date(from: timestamp) {
                let dayKey = DateFormatter.shortDate.string(from: date)
                let timeKey = DateFormatter.shortTime.string(from: date)
                
                if activitiesByDate[dayKey] == nil {
                    activitiesByDate[dayKey] = []
                }
                activitiesByDate[dayKey]?.append((time: timeKey, activity: activity, action: action))
            }
        }
        
        // Generate report sections
        let sortedDates = activitiesByDate.keys.sorted()
        for dateKey in sortedDates {
            guard let activities = activitiesByDate[dateKey] else { continue }
            
            report += """
            📅 \(dateKey)
            ----------------------------------------
            
            """
            
            var dailyTotal: TimeInterval = 0
            var activityTotals: [String: TimeInterval] = [:]
            
            var currentActivity: String?
            var startTime: Date?
            
            for activity in activities {
                report += "\(activity.time) - \(activity.action): \(activity.activity)\n"
                
                if activity.action.contains("START") || activity.action.contains("QUICK_START") {
                    currentActivity = activity.activity
                    let fullTime = "\(dateKey) \(activity.time)"
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "M/d/yy h:mm a"
                    startTime = timeFormatter.date(from: fullTime)
                } else if activity.action.contains("END") && currentActivity != nil {
                    if let start = startTime {
                        let fullTime = "\(dateKey) \(activity.time)"
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateFormat = "M/d/yy h:mm a"
                        if let end = timeFormatter.date(from: fullTime) {
                            let duration = end.timeIntervalSince(start)
                            dailyTotal += duration
                            activityTotals[currentActivity!] = (activityTotals[currentActivity!] ?? 0) + duration
                        }
                    }
                    currentActivity = nil
                    startTime = nil
                }
            }
            
            // Daily summary
            report += "\n📊 Daily Summary:\n"
            let hours = Int(dailyTotal) / 3600
            let minutes = Int(dailyTotal) % 3600 / 60
            report += "Total Time: \(hours)h \(minutes)m\n"
            
            for (activity, duration) in activityTotals.sorted(by: { $0.value > $1.value }) {
                let actHours = Int(duration) / 3600
                let actMinutes = Int(duration) % 3600 / 60
                report += "• \(activity): \(actHours)h \(actMinutes)m\n"
            }
            
            report += "\n"
        }
        
        return report
    }
    
    private func showAlert(title: String, message: String) {
        AlertManager.shared.showAlert(
            type: .info,
            title: title,
            message: message
        )
    }
    
    
    private func generateReportFromEntries(_ entries: [ActivityLogEntry]) -> String {
        let displayDateFormatter = DateFormatter()
        displayDateFormatter.dateFormat = "yyyy-MM-dd"
        
        var report = """
        =====================================================
        📊 TIMEDECK ACTIVITY REPORT
        =====================================================
        Generated: \(displayDateFormatter.string(from: Date())) \(DateFormatter.shortTime.string(from: Date()))
        Report Period: Last 30 days
        
        📈 ACTIVITY SUMMARY:
        """
        
        // Calculate total stats from entries
        var activities: [String: TimeInterval] = [:]
        var currentActivity: String?
        var currentStartTime: Date?
        var totalTrackedTime: TimeInterval = 0
        var dailyStats: [String: TimeInterval] = [:] // date -> total time
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let dayKey = dateFormatter.string(from: entry.timestamp)
            
            switch entry.action {
            case .start, .quickStart, .resume:
                currentActivity = entry.activityName
                currentStartTime = entry.timestamp
                
            case .end, .pause:
                if let activity = currentActivity,
                   let startTime = currentStartTime {
                    let duration = entry.timestamp.timeIntervalSince(startTime)
                    activities[activity] = (activities[activity] ?? 0) + duration
                    totalTrackedTime += duration
                    dailyStats[dayKey] = (dailyStats[dayKey] ?? 0) + duration
                }
                if entry.action == .end {
                    currentActivity = nil
                    currentStartTime = nil
                }
            default:
                break
            }
        }
        
        // Add summary stats
        let totalHours = totalTrackedTime / 3600
        let avgDailyHours = dailyStats.values.isEmpty ? 0 : totalTrackedTime / TimeInterval(dailyStats.count) / 3600
        
        report += """
        
           • Total Tracked Time: \(String(format: "%.1f", totalHours)) hours
           • Active Days: \(dailyStats.count)
           • Average Daily Time: \(String(format: "%.1f", avgDailyHours)) hours
           • Number of Activities: \(activities.count)
        
        🎯 ACTIVITY BREAKDOWN:
        """
        
        let sortedActivities = activities.sorted { $0.value > $1.value }
        for (activity, duration) in sortedActivities {
            let hours = duration / 3600
            let percentage = totalTrackedTime > 0 ? (duration / totalTrackedTime) * 100 : 0
            report += "   • \(activity): \(String(format: "%.1f", hours))h (\(String(format: "%.1f", percentage))%)\n"
        }
        
        report += "\n📅 DAILY BREAKDOWN:\n"
        let sortedDays = dailyStats.sorted { $0.key > $1.key } // Recent first
        for (day, duration) in sortedDays.prefix(10) { // Show last 10 days
            let hours = duration / 3600
            report += "   • \(day): \(String(format: "%.1f", hours))h\n"
        }
        
        if sortedDays.count > 10 {
            report += "   ... and \(sortedDays.count - 10) more days\n"
        }
        
        report += """
        
        =====================================================
        📊 END OF REPORT
        =====================================================
        """
        
        return report
    }
}
