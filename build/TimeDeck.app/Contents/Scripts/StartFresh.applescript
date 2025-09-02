-- Start Fresh AppleScript for StreamDeck
-- This script clears the activity log file to start fresh

on run
    -- Set file paths (get actual home directory)
    set homeDir to do shell script "echo $HOME"
    set logFilePath to homeDir & "/Desktop/timedeck_log.txt"
    set reportFilePath to homeDir & "/Desktop/timedeck_report.txt"
    
    try
        -- Confirm with user before clearing
        set userChoice to display dialog "Are you sure you want to clear all activity data and start fresh?" with title "Start Fresh" buttons {"Cancel", "Clear All Data"} default button "Cancel" with icon caution
        
        if button returned of userChoice is "Clear All Data" then
            -- Delete the files
            do shell script "rm -f " & quoted form of logFilePath & " " & quoted form of reportFilePath
            
            -- Show confirmation
            display notification "Activity data cleared successfully!" with title "TimeDeck - Start Fresh"
            display dialog "✅ Activity data has been cleared successfully!" & return & return & "You can now start tracking fresh activities." with title "Start Fresh Complete" buttons {"OK"} default button "OK"
            
        else
            -- User cancelled
            display notification "Start Fresh cancelled" with title "TimeDeck"
            display dialog "Start Fresh operation was cancelled. Your activity data remains unchanged." with title "Cancelled" buttons {"OK"} default button "OK"
        end if
        
    on error errMsg
        -- Handle any errors (including user cancellation)
        if errMsg contains "User canceled" then
            display notification "Start Fresh cancelled" with title "TimeDeck"
            display dialog "Start Fresh operation was cancelled. Your activity data remains unchanged." with title "Cancelled" buttons {"OK"} default button "OK"
        else
            display notification "Error clearing data" with title "TimeDeck - Error"
            display dialog "❌ Error clearing activity data:" & return & return & errMsg with title "Error" buttons {"OK"} default button "OK" with icon stop
        end if
    end try
    
end run
