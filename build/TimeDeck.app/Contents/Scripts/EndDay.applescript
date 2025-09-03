-- End Day AppleScript for StreamDeck
-- This script calculates time spent on each activity for the current day

on run
    -- Set the path to the activities log file (get actual home directory)
    set homeDir to do shell script "echo $HOME"
    set logFilePath to homeDir & "/Desktop/timedeck_log.txt"
    
    try
        -- Read the log file using shell script
        set logContents to do shell script "cat " & quoted form of logFilePath
        
        -- Check if there's an open activity and end it first
        set logLines to paragraphs of logContents
        if (count of logLines) > 0 then
            set lastLine to item -1 of logLines
            if lastLine is not "" then
                -- Handle both old and new timestamp formats
                if (count of characters of lastLine) > 19 and (text 5 thru 5 of lastLine) is "-" then
                    -- New format: "YYYY-MM-DD HH:MM:SS activity name"
                    set lastActivity to text 21 thru -1 of lastLine
                else
                    -- Old format: "UNIX_TIMESTAMP activity name"
                    set spaceIndex to offset of " " in lastLine
                    if spaceIndex > 0 then
                        set lastActivity to text (spaceIndex + 1) thru -1 of lastLine
                    else
                        set lastActivity to ""
                    end if
                end if
                
                -- If the last entry is not "END", we have an open activity
                if lastActivity is not "END" then
                    -- Get current timestamp and add END marker
                    set currentTimestamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
                    set endEntry to currentTimestamp & " END"
                    do shell script "printf '%s\\n' " & quoted form of endEntry & " >> " & quoted form of logFilePath
                    
                    -- Re-read the log file to include the END marker
                    set logContents to do shell script "cat " & quoted form of logFilePath
                    
                    -- Show notification that we ended the open activity
                    display notification "Open activity automatically ended for day summary" with title "TimeDeck - End Day"
                end if
            end if
        end if
        
        -- Get today's date in UNIX timestamp range
        set todayStart to do shell script "date -j -v0H -v0M -v0S '+%s'"
        set todayEnd to do shell script "date -j -v23H -v59M -v59S '+%s'"
        
        -- Parse log entries for today
        set todayEntries to {}
        set logLines to paragraphs of logContents
        
        repeat with logLine in logLines
            set logLineStr to logLine as string
            if logLineStr is not "" then
                -- Handle both old (UNIX timestamp) and new (human-readable) formats
                if (count of characters of logLineStr) > 19 and (text 5 thru 5 of logLineStr) is "-" then
                    -- New format: "YYYY-MM-DD HH:MM:SS activity name"
                    set entryTimestamp to text 1 thru 19 of logLineStr
                    set activityName to text 21 thru -1 of logLineStr
                    
                    -- Convert human-readable timestamp to UNIX timestamp for comparison
                    try
                        set entryUnixTime to do shell script "date -jf '%Y-%m-%d %H:%M:%S' '" & entryTimestamp & "' +%s"
                        
                        -- Check if entry is from today
                        if (entryUnixTime as integer) ≥ (todayStart as integer) and (entryUnixTime as integer) ≤ (todayEnd as integer) then
                            set end of todayEntries to {timestamp:entryUnixTime as integer, activity:activityName}
                        end if
                    on error
                        -- Skip malformed entries
                    end try
                else
                    -- Old format: "UNIX_TIMESTAMP activity name"
                    set spaceIndex to offset of " " in logLineStr
                    if spaceIndex > 0 then
                        set entryTimestamp to text 1 thru (spaceIndex - 1) of logLineStr
                        set activityName to text (spaceIndex + 1) thru -1 of logLineStr
                        
                        -- Check if entry is from today
                        if (entryTimestamp as integer) ≥ (todayStart as integer) and (entryTimestamp as integer) ≤ (todayEnd as integer) then
                            set end of todayEntries to {timestamp:entryTimestamp as integer, activity:activityName}
                        end if
                    end if
                end if
            end if
        end repeat
        
        -- Sort entries by timestamp
        set sortedEntries to my sortEntriesByTimestamp(todayEntries)
        
        -- Calculate time spent on each activity
        set activityTimes to {}
        set currentActivity to ""
        set currentStartTime to 0
        
        repeat with i from 1 to count of sortedEntries
            set currentEntry to item i of sortedEntries
            set entryActivity to activity of currentEntry
            set entryTimestamp to timestamp of currentEntry
            
            -- If we have a previous activity, calculate its duration
            if currentActivity is not "" then
                set duration to entryTimestamp - currentStartTime
                set found to false
                
                -- Update existing activity time or add new one
                repeat with j from 1 to count of activityTimes
                    set activityRecord to item j of activityTimes
                    if activityName of activityRecord is currentActivity then
                        set totalTime of activityRecord to (totalTime of activityRecord) + duration
                        set found to true
                        exit repeat
                    end if
                end repeat
                
                if not found then
                    set end of activityTimes to {activityName:currentActivity, totalTime:duration}
                end if
            end if
            
            -- Handle END markers - don't set them as the new current activity
            if entryActivity is "END" then
                set currentActivity to ""
                set currentStartTime to 0
            else
                -- Set up for next iteration with new activity
                set currentActivity to entryActivity
                set currentStartTime to entryTimestamp
            end if
        end repeat
        
        -- Handle the last activity (assume it ended at current time if it's the last entry)
        if currentActivity is not "" then
            set currentTime to do shell script "date +%s"
            set duration to (currentTime as integer) - currentStartTime
            set found to false
            
            repeat with j from 1 to count of activityTimes
                set activityRecord to item j of activityTimes
                if activityName of activityRecord is currentActivity then
                    set totalTime of activityRecord to (totalTime of activityRecord) + duration
                    set found to true
                    exit repeat
                end if
            end repeat
            
            if not found then
                set end of activityTimes to {activityName:currentActivity, totalTime:duration}
            end if
        end if
        
        -- Format and display results
        set resultText to "Today's Activity Summary:" & return & return
        set totalDayTime to 0
        
        repeat with activityRecord in activityTimes
            set activityName to activityName of activityRecord
            set totalSeconds to totalTime of activityRecord
            set hours to totalSeconds div 3600
            set minutes to (totalSeconds mod 3600) div 60
            set secs to totalSeconds mod 60
            
            set timeString to hours & "h " & minutes & "m " & secs & "s"
            set resultText to resultText & activityName & ": " & timeString & return
            set totalDayTime to totalDayTime + totalSeconds
        end repeat
        
        -- Add total time
        set totalHours to totalDayTime div 3600
        set totalMinutes to (totalDayTime mod 3600) div 60
        set totalSecsRemainder to totalDayTime mod 60
        set totalTimeString to totalHours & "h " & totalMinutes & "m " & totalSecsRemainder & "s"
        set resultText to resultText & return & "Total tracked time: " & totalTimeString
        
        -- Display results
        display dialog resultText with title "End of Day Summary" buttons {"OK"} default button "OK"
        
    on error errMsg
        display dialog "Error reading log file: " & errMsg with title "Error"
    end try
    
end run

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
