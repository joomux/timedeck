-- End Activity AppleScript for StreamDeck
-- This script ends the current activity without starting a new one

on run
    -- Set the path to the activities log file (get actual home directory)
    set homeDir to do shell script "echo $HOME"
    set logFilePath to homeDir & "/Desktop/timedeck_log.txt"
    
    try
        -- Check if log file exists, if not create it
        try
            set logContents to do shell script "cat " & quoted form of logFilePath
        on error
            -- File doesn't exist, no activity to end
            display notification "No activity log found - nothing to end" with title "TimeDeck"
            return
        end try
        
        -- Check if there's an open activity
        set logLines to paragraphs of logContents
        if (count of logLines) > 0 then
            set lastLine to item -1 of logLines
            if lastLine is not "" then
                set spaceIndex to offset of " " in lastLine
                if spaceIndex > 0 then
                    set lastActivity to text (spaceIndex + 1) thru -1 of lastLine
                    
                    -- If the last entry is already "END", don't add another
                    if lastActivity is "END" then
                        display notification "No active activity to end" with title "TimeDeck"
                        return
                    end if
                    
                    -- We have an open activity, end it
                    set currentTimestamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
                    set logEntry to currentTimestamp & " END"
                    
                    -- Append to the log file using printf for safer escaping
                    do shell script "printf '%s\\n' " & quoted form of logEntry & " >> " & quoted form of logFilePath
                    
                    -- Show confirmation
                    display notification "Activity \"" & lastActivity & "\" ended" with title "TimeDeck"
                else
                    -- Malformed last line
                    display notification "Log file format error - cannot determine current activity" with title "TimeDeck Error"
                end if
            else
                -- Empty last line, but might have other entries
                display notification "No active activity to end" with title "TimeDeck"
            end if
        else
            -- Empty log file
            display notification "No activities logged yet - nothing to end" with title "TimeDeck"
        end if
        
    on error errMsg
        display dialog "Error processing log file: " & errMsg with title "Error"
    end try
    
end run
