-- Debug version of Activity Status to track exactly what's happening

on run
    set homeDir to do shell script "echo $HOME"
    set logFilePath to homeDir & "/Desktop/timedeck_log.txt"
    set debugFilePath to homeDir & "/Desktop/activity_debug.txt"
    
    -- Initialize debug log
    set debugInfo to "=== Activity Status Debug ===" & return & return
    
    try
        -- Step 1: Check if log file exists
        try
            set logContents to do shell script "cat " & quoted form of logFilePath
            set debugInfo to debugInfo & "✅ Step 1: Log file read successfully" & return
            set debugInfo to debugInfo & "📄 Log contents: " & logContents & return & return
        on error errMsg
            set debugInfo to debugInfo & "❌ Step 1: Cannot read log file - " & errMsg & return
            do shell script "printf '%s' " & quoted form of debugInfo & " > " & quoted form of debugFilePath
            return
        end try
        
        -- Step 2: Parse log lines
        set logLines to paragraphs of logContents
        set debugInfo to debugInfo & "✅ Step 2: Split into " & (count of logLines) & " lines" & return
        
        if (count of logLines) > 0 then
            set lastLine to item -1 of logLines
            set debugInfo to debugInfo & "📝 Last line: '" & lastLine & "'" & return
            
            if lastLine is not "" then
                -- Step 3: Parse timestamp and activity
                set spaceIndex to offset of " " in lastLine
                set debugInfo to debugInfo & "✅ Step 3: Space found at position " & spaceIndex & return
                
                if spaceIndex > 0 then
                    set lastTimestamp to text 1 thru (spaceIndex - 1) of lastLine
                    set lastActivity to text (spaceIndex + 1) thru -1 of lastLine
                    set debugInfo to debugInfo & "🕐 Extracted timestamp: '" & lastTimestamp & "'" & return
                    set debugInfo to debugInfo & "📋 Extracted activity: '" & lastActivity & "'" & return & return
                    
                    -- Step 4: Test date command with extracted timestamp
                    set debugInfo to debugInfo & "🧪 Step 4: Testing date command..." & return
                    try
                        set startTimeFormatted to do shell script "date -r " & lastTimestamp & " +%H:%M"
                        set debugInfo to debugInfo & "✅ Date command SUCCESS: " & startTimeFormatted & return
                    on error dateErrMsg
                        set debugInfo to debugInfo & "❌ Date command FAILED: " & dateErrMsg & return
                        
                        -- Try to understand why it failed
                        try
                            set timestampCheck to do shell script "echo '" & lastTimestamp & "' | grep -E '^[0-9]+$'"
                            set debugInfo to debugInfo & "✅ Timestamp is numeric: " & timestampCheck & return
                        on error
                            set debugInfo to debugInfo & "❌ Timestamp is NOT numeric" & return
                        end try
                        
                        -- Try basic date command
                        try
                            set basicDate to do shell script "date +%H:%M"
                            set debugInfo to debugInfo & "✅ Basic date works: " & basicDate & return
                        on error basicErrMsg
                            set debugInfo to debugInfo & "❌ Basic date fails: " & basicErrMsg & return
                        end try
                    end try
                else
                    set debugInfo to debugInfo & "❌ Step 3: No space found in last line" & return
                end if
            else
                set debugInfo to debugInfo & "❌ Step 2: Last line is empty" & return
            end if
        else
            set debugInfo to debugInfo & "❌ Step 2: No lines in log file" & return
        end if
        
        -- Write debug info to file
        do shell script "printf '%s' " & quoted form of debugInfo & " > " & quoted form of debugFilePath
        
        -- Show summary in dialog
        display dialog "Debug complete! Check ~/Desktop/activity_debug.txt for details" with title "Debug Results"
        
    on error mainErrMsg
        set debugInfo to debugInfo & "💥 MAIN ERROR: " & mainErrMsg & return
        do shell script "printf '%s' " & quoted form of debugInfo & " > " & quoted form of debugFilePath
        display dialog "Error occurred. Check ~/Desktop/activity_debug.txt" with title "Debug Error"
    end try
end run
