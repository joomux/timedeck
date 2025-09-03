-- Generate Report AppleScript for StreamDeck
-- This script creates a detailed report of all activity data grouped by date

on run
    -- Set file paths (get actual home directory)
set homeDir to do shell script "echo $HOME"
set logFilePath to homeDir & "/Desktop/timedeck_log.txt"
set reportFilePath to homeDir & "/Desktop/timedeck_report.txt"
    
    try
        -- Read the log file
        set logContents to do shell script "cat " & quoted form of logFilePath
        
        -- Parse all log entries
        set allEntries to {}
        set logLines to paragraphs of logContents
        
        repeat with logLine in logLines
            set logLineStr to logLine as string
            if logLineStr is not "" then
                -- Handle both old (UNIX timestamp) and new (human-readable) formats
                if (count of characters of logLineStr) > 19 and (text 5 thru 5 of logLineStr) is "-" then
                    -- New format: "YYYY-MM-DD HH:MM:SS activity name"
                    set entryTimestamp to text 1 thru 19 of logLineStr
                    set activityName to text 21 thru -1 of logLineStr
                    
                    -- Extract date and time directly from human-readable format
                    set dateStr to text 1 thru 10 of entryTimestamp
                    set timeStr to text 12 thru 19 of entryTimestamp
                    
                    -- Convert to UNIX timestamp for calculations
                    try
                        set entryUnixTime to do shell script "date -jf '%Y-%m-%d %H:%M:%S' '" & entryTimestamp & "' +%s"
                        set end of allEntries to {timestamp:(entryUnixTime as integer), activity:activityName, dateStr:dateStr, timeStr:timeStr}
                    on error
                        -- Skip malformed entries
                    end try
                else
                    -- Old format: "UNIX_TIMESTAMP activity name"
                    set spaceIndex to offset of " " in logLineStr
                    if spaceIndex > 0 then
                        set entryTimestamp to text 1 thru (spaceIndex - 1) of logLineStr
                        set activityName to text (spaceIndex + 1) thru -1 of logLineStr
                        
                        -- Convert timestamp to date for grouping
                        try
                            set dateStr to do shell script "date -r " & entryTimestamp & " '+%Y-%m-%d'"
                            set timeStr to do shell script "date -r " & entryTimestamp & " '+%H:%M:%S'"
                            
                            set end of allEntries to {timestamp:(entryTimestamp as integer), activity:activityName, dateStr:dateStr, timeStr:timeStr}
                        on error
                            -- Skip malformed entries
                        end try
                    end if
                end if
            end if
        end repeat
        
        -- Sort entries by timestamp
        set sortedEntries to my sortEntriesByTimestamp(allEntries)
        
        -- Group entries by date and calculate sessions
        set dailyReports to {}
        set currentDate to ""
        set currentDateEntries to {}
        
        repeat with entry in sortedEntries
            if dateStr of entry is not currentDate then
                -- Process previous date if we have entries
                if currentDate is not "" then
                    set dailySessions to my calculateDailySessions(currentDateEntries)
                    set end of dailyReports to {dateStr:currentDate, sessions:dailySessions}
                end if
                
                -- Start new date
                set currentDate to dateStr of entry
                set currentDateEntries to {entry}
            else
                -- Add to current date
                set end of currentDateEntries to entry
            end if
        end repeat
        
        -- Process the last date
        if currentDate is not "" then
            set dailySessions to my calculateDailySessions(currentDateEntries)
            set end of dailyReports to {dateStr:currentDate, sessions:dailySessions}
        end if
        
        -- Generate report content
        set reportContent to my formatReport(dailyReports)
        
        -- Write report to file
        do shell script "printf '%s' " & quoted form of reportContent & " > " & quoted form of reportFilePath
        
        -- Show completion message
        display notification "Activity report generated successfully!" with title "TimeDeck Report"
        display dialog "Activity report has been generated and saved to:" & return & return & "~/Desktop/timedeck_report.txt" & return & return & "The report contains detailed activity sessions grouped by date with start times and durations." with title "Report Generated" buttons {"Open Report", "OK"} default button "OK"
        
        set dialogResult to result
        if button returned of dialogResult is "Open Report" then
            do shell script "open -t " & quoted form of reportFilePath
        end if
        
    on error errMsg
        display dialog "Error generating report: " & errMsg with title "Error"
    end try
    
end run

-- Calculate daily sessions with start times and durations
on calculateDailySessions(dateEntries)
    set sessions to {}
    set currentActivity to ""
    set currentStartTime to 0
    set currentStartTimeStr to ""
    
    repeat with entry in dateEntries
        set entryActivity to activity of entry
        set entryTimestamp to timestamp of entry
        set entryTimeStr to timeStr of entry
        
        -- If we have a previous activity, calculate its duration
        if currentActivity is not "" then
            set duration to entryTimestamp - currentStartTime
            set durationHours to my formatDuration(duration)
            
            set end of sessions to {activity:currentActivity, startTime:currentStartTimeStr, duration:durationHours, durationSeconds:duration}
        end if
        
        -- Handle END markers - don't set them as the new current activity
        if entryActivity is "END" then
            set currentActivity to ""
            set currentStartTime to 0
            set currentStartTimeStr to ""
        else
            -- Set up for next iteration with new activity
            set currentActivity to entryActivity
            set currentStartTime to entryTimestamp
            set currentStartTimeStr to entryTimeStr
        end if
    end repeat
    
    -- Handle the last activity of the day (if not ended with END marker)
    if currentActivity is not "" then
        -- For ongoing activities, we'll mark them as "ongoing" or estimate until end of work day
        set currentTime to do shell script "date +%s"
        set duration to (currentTime as integer) - currentStartTime
        set durationHours to my formatDuration(duration)
        
        set end of sessions to {activity:currentActivity, startTime:currentStartTimeStr, duration:durationHours & " (ongoing)", durationSeconds:duration}
    end if
    
    return sessions
end calculateDailySessions

-- Format duration in hours and minutes
on formatDuration(totalSeconds)
    set hours to totalSeconds div 3600
    set minutes to (totalSeconds mod 3600) div 60
    
    if hours > 0 then
        return hours & "h " & minutes & "m"
    else
        return minutes & "m"
    end if
end formatDuration

-- Format the complete report
on formatReport(dailyReports)
    set LF to ASCII character 10 -- Line feed for Unix compatibility
    set reportContent to "HACKTIVITY DETAILED REPORT" & LF
    set reportContent to reportContent & "Generated: " & (do shell script "date '+%Y-%m-%d %H:%M:%S'") & LF
    set reportContent to reportContent & "================================================================================" & LF & LF
    
    set totalTrackedTime to 0
    set totalDays to count of dailyReports
    
    repeat with dailyReport in dailyReports
        set reportDate to dateStr of dailyReport
        set sessions to sessions of dailyReport
        
        -- Format date header
        set dayOfWeek to do shell script "date -j -f '%Y-%m-%d' " & reportDate & " '+%A'"
        set readableDate to do shell script "date -j -f '%Y-%m-%d' " & reportDate & " '+%B %d, %Y'"
        
        set reportContent to reportContent & dayOfWeek & " - " & readableDate & LF
        set reportContent to reportContent & "--------------------------------------------------" & LF
        
        if (count of sessions) = 0 then
            set reportContent to reportContent & "No activities logged" & LF & LF
        else
            set dailyTotal to 0
            
            repeat with session in sessions
                set activityName to activity of session
                set startTime to startTime of session
                set duration to duration of session
                set durationSecs to durationSeconds of session
                
                set reportContent to reportContent & startTime & "  |  " & duration & "  |  " & activityName & LF
                set dailyTotal to dailyTotal + durationSecs
            end repeat
            
            set dailyTotalFormatted to my formatDuration(dailyTotal)
            set reportContent to reportContent & LF & "Daily Total: " & dailyTotalFormatted & LF & LF
            set totalTrackedTime to totalTrackedTime + dailyTotal
        end if
    end repeat
    
    -- Add summary
    set reportContent to reportContent & "================================================================================" & LF
    set reportContent to reportContent & "SUMMARY" & LF
    set reportContent to reportContent & "================================================================================" & LF
    set reportContent to reportContent & "Total days: " & totalDays & LF
    set reportContent to reportContent & "Total tracked time: " & my formatDuration(totalTrackedTime) & LF
    
    if totalDays > 0 then
        set avgPerDay to totalTrackedTime / totalDays
        set reportContent to reportContent & "Average per day: " & my formatDuration(avgPerDay) & LF
    end if
    
    return reportContent
end formatReport

-- Helper function to sort entries by timestamp
on sortEntriesByTimestamp(entryList)
    set sortedList to {}
    repeat with currentEntry in entryList
        set inserted to false
        repeat with i from 1 to count of sortedList
            if timestamp of currentEntry < timestamp of (item i of sortedList) then
                set sortedList to (items 1 thru (i - 1) of sortedList) & {currentEntry} & (items i thru -1 of sortedList)
                set inserted to true
                exit repeat
            end if
        end repeat
        if not inserted then
            set end of sortedList to currentEntry
        end if
    end repeat
    return sortedList
end sortEntriesByTimestamp
