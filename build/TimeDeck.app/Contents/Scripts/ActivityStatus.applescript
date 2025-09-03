-- Activity Status AppleScript for TimeDeck
-- This script shows current activity status with detailed information

on run
    -- Set the path to the activities log file (get actual home directory)
    set homeDir to do shell script "echo $HOME"
    set logFilePath to homeDir & "/Desktop/timedeck_log.txt"
    
    try
        -- Check if log file exists
        try
            set logContents to do shell script "cat " & quoted form of logFilePath
        on error
            -- File doesn't exist
            display dialog "📊 Activity Status" & return & return & "No activity log found." & return & "Start tracking activities to see status!" with title "TimeDeck - Activity Status" buttons {"OK"} default button "OK"
            return
        end try
        
        -- Get today's date in UNIX timestamp range
        try
            set todayStart to do shell script "date -j -v0H -v0M -v0S '+%s'"
            set todayEnd to do shell script "date -j -v23H -v59M -v59S '+%s'"
            set currentTime to do shell script "date +%s"
        on error errMsg
            display dialog "Error getting current time: " & errMsg with title "TimeDeck Error"
            return
        end try
        
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
                            set end of todayEntries to {timestamp:entryTimestamp, unixTime:entryUnixTime as integer, activity:activityName}
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
                        try
                            if (entryTimestamp as integer) ≥ (todayStart as integer) and (entryTimestamp as integer) ≤ (todayEnd as integer) then
                                -- Convert UNIX timestamp to human-readable for display
                                set readableTimestamp to do shell script "date -r " & entryTimestamp & " '+%Y-%m-%d %H:%M:%S'"
                                set end of todayEntries to {timestamp:readableTimestamp, unixTime:entryTimestamp as integer, activity:activityName}
                            end if
                        on error
                            -- Skip malformed entries
                        end try
                    end if
                end if
            end if
        end repeat
        
        -- Sort entries by timestamp
        set sortedEntries to my sortEntriesByTimestamp(todayEntries)
        
        if (count of sortedEntries) = 0 then
            display dialog "📊 Activity Status" & return & return & "No activities tracked today." & return & "Start a new activity to begin tracking!" with title "TimeDeck - Activity Status" buttons {"OK"} default button "OK"
            return
        end if
        
        -- Check current activity status
        set lastEntry to item -1 of sortedEntries
        set lastActivity to activity of lastEntry
        set lastTimestamp to timestamp of lastEntry
        set lastUnixTime to unixTime of lastEntry
        
        set statusText to "📊 Today's Activity Status" & return & return
        
        -- Show current activity status
        if lastActivity is "END" then
            set statusText to statusText & "🔴 Current Status: No active activity" & return & return
        else
            -- Calculate current activity duration
            set currentDuration to (currentTime as integer) - lastUnixTime
            set hours to currentDuration div 3600
            set minutes to (currentDuration mod 3600) div 60
            set secs to currentDuration mod 60
            
            -- Extract just the time part (HH:MM) from the timestamp
            set startTimeFormatted to text 12 thru 16 of lastTimestamp
            
            set statusText to statusText & "🟢 Current Activity: " & lastActivity & return
            set statusText to statusText & "⏰ Started: " & startTimeFormatted & return
            -- Convert to decimal hours for display
            set decimalHours to hours + (minutes / 60.0)
            set formattedHours to (round (decimalHours * 10)) / 10 -- Round to 1 decimal place
            
            if formattedHours = 1 then
                set hourText to " hour"
            else
                set hourText to " hours"
            end if
            
            set statusText to statusText & "⏱️ Duration: " & formattedHours & hourText & return & return
        end if
        
        -- Show today's activity summary
        set activityTimes to {}
        set currentActivity to ""
        set currentStartTime to 0
        
        repeat with i from 1 to count of sortedEntries
            set currentEntry to item i of sortedEntries
            set entryActivity to activity of currentEntry
            set entryUnixTime to unixTime of currentEntry
            
            -- If we have a previous activity, calculate its duration
            if currentActivity is not "" then
                set duration to entryUnixTime - currentStartTime
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
            
            -- Handle END markers
            if entryActivity is "END" then
                set currentActivity to ""
                set currentStartTime to 0
            else
                set currentActivity to entryActivity
                set currentStartTime to entryUnixTime
            end if
        end repeat
        
        -- Handle ongoing activity (add time up to now)
        if currentActivity is not "" then
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
        
        -- Add today's summary
        set statusText to statusText & "📈 Today's Summary:" & return
        set totalDayTime to 0
        
        if (count of activityTimes) > 0 then
            repeat with activityRecord in activityTimes
                set activityName to activityName of activityRecord
                set totalSeconds to totalTime of activityRecord
                set hours to totalSeconds div 3600
                set minutes to (totalSeconds mod 3600) div 60
                
                -- Convert to decimal hours for display
                set decimalHours to hours + (minutes / 60.0)
                set formattedHours to (round (decimalHours * 10)) / 10 -- Round to 1 decimal place
                
                if formattedHours = 1 then
                    set timeString to formattedHours & " hour"
                else
                    set timeString to formattedHours & " hours"
                end if
                set statusText to statusText & "  • " & activityName & ": " & timeString & return
                set totalDayTime to totalDayTime + totalSeconds
            end repeat
            
            -- Add total time
            set totalHours to totalDayTime div 3600
            set totalMinutes to (totalDayTime mod 3600) div 60
            
            -- Convert to decimal hours for display
            set totalDecimalHours to totalHours + (totalMinutes / 60.0)
            set formattedTotalHours to (round (totalDecimalHours * 10)) / 10 -- Round to 1 decimal place
            
            if formattedTotalHours = 1 then
                set totalTimeString to formattedTotalHours & " hour"
            else
                set totalTimeString to formattedTotalHours & " hours"
            end if
            set statusText to statusText & return & "🕐 Total tracked today: " & totalTimeString
        else
            set statusText to statusText & "  No completed activities yet today."
        end if
        
        -- Display the status
        display dialog statusText with title "TimeDeck - Activity Status" buttons {"OK"} default button "OK"
        
    on error errMsg
        display dialog "Error reading activity status: " & errMsg with title "TimeDeck Error"
    end try
end run

-- Helper function to sort entries by timestamp
on sortEntriesByTimestamp(entryList)
    set sortedList to {}
    repeat with currentEntry in entryList
        set inserted to false
        repeat with i from 1 to count of sortedList
            if unixTime of currentEntry < unixTime of (item i of sortedList) then
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
