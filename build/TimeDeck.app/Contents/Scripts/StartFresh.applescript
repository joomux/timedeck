-- Start Fresh AppleScript for StreamDeck
-- This script clears the activity log file to start fresh

on run
    -- Set the path to the activities log file
    set logFilePath to "~/Desktop/timedeck_log.txt"
    
    -- Confirm with user before clearing
    display dialog "Are you sure you want to clear all activity data and start fresh?" with title "Start Fresh" buttons {"Cancel", "Clear All Data"} default button "Cancel" with icon caution
    
    if button returned of result is "Clear All Data" then
        try
            -- Clear the log file
            do shell script "echo '' > " & logFilePath
            
            -- Show confirmation
            display notification "Activity log cleared successfully!" with title "Hacktivity - Start Fresh"
            display dialog "Activity log has been cleared. You can now start tracking fresh activities." with title "Start Fresh Complete" buttons {"OK"} default button "OK"
            
        on error errMsg
            display dialog "Error clearing log file: " & errMsg with title "Error"
        end try
    else
        -- User cancelled
        display notification "Start Fresh cancelled" with title "Hacktivity"
    end if
    
end run
