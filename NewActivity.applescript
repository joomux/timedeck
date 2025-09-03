-- New Activity AppleScript for StreamDeck
-- This script logs a new activity with a timestamp

on run argv
    -- Get the activity name from argument or prompt user
    set activityName to ""
    
    if (count of argv) > 0 then
        set activityName to item 1 of argv
    else
        -- Prompt user for activity name
        display dialog "Enter activity name:" default answer "" with title "New Activity"
        set activityName to text returned of result
    end if
    
    -- Exit if no activity name provided
    if activityName is "" then
        display dialog "No activity name provided. Exiting." with title "Error"
        return
    end if
    
    -- Get current human-readable timestamp
    set currentTimestamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
    
    -- Create log entry
    set logEntry to currentTimestamp & " " & activityName
    
    -- Set the path to the activities log file (get actual home directory)
    set homeDir to do shell script "echo $HOME"
    set logFilePath to homeDir & "/Desktop/timedeck_log.txt"
    
    try
        -- Append to the log file using printf for safer escaping
        do shell script "printf '%s\\n' " & quoted form of logEntry & " >> " & quoted form of logFilePath
        
        -- Show confirmation
        display notification "Activity logged: " & activityName with title "TimeDeck"
        
    on error errMsg
        display dialog "Error writing to log file: " & errMsg with title "Error"
    end try
    
end run
