-- End Activity AppleScript for StreamDeck
-- This script ends the current activity without starting a new one

on run
    -- Get current UNIX timestamp
    set currentTimestamp to do shell script "date +%s"
    
    -- Create log entry to mark end of current activity
    set logEntry to currentTimestamp & " END"
    
    -- Set the path to the activities log file
    set logFilePath to "~/Desktop/hacktivity_log.txt"
    
    try
        -- Append to the log file using printf for safer escaping
        do shell script "printf '%s\\n' " & quoted form of logEntry & " >> " & logFilePath
        
        -- Show confirmation
        display notification "Current activity ended" with title "Hacktivity"
        
    on error errMsg
        display dialog "Error writing to log file: " & errMsg with title "Error"
    end try
    
end run
