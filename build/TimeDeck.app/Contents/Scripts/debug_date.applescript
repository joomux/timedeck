-- Debug script to test date formatting

-- Create test data
set testTimestamp to 1756875787

-- Test the date command
try
    set dateResult to do shell script "date -r " & (testTimestamp as string) & " +%H:%M"
    set debugMessage to "Success: " & dateResult
on error errMsg
    set debugMessage to "Error: " & errMsg
end try

-- Also test if timestamp is being read correctly from log
set homeDir to do shell script "echo $HOME"
set logFilePath to homeDir & "/Desktop/timedeck_log.txt"

-- Create test log
do shell script "echo '" & testTimestamp & " Test Activity' > " & quoted form of logFilePath

-- Read it back
try
    set logContents to do shell script "cat " & quoted form of logFilePath
    set logLines to paragraphs of logContents
    set lastLine to item -1 of logLines
    set spaceIndex to offset of " " in lastLine
    set extractedTimestamp to text 1 thru (spaceIndex - 1) of lastLine
    set activityName to text (spaceIndex + 1) thru -1 of lastLine
    
    set logDebug to "Log parsing: timestamp='" & extractedTimestamp & "', activity='" & activityName & "'"
    
    -- Test date formatting with extracted timestamp
    try
        set extractedDateResult to do shell script "date -r " & extractedTimestamp & " +%H:%M"
        set extractedDebug to "Extracted date success: " & extractedDateResult
    on error errMsg2
        set extractedDebug to "Extracted date error: " & errMsg2
    end try
    
on error errMsg3
    set logDebug to "Log read error: " & errMsg3
    set extractedDebug to "No extracted test"
end try

-- Write debug info to file instead of popup
set fullDebug to "Debug Results:" & return & return & debugMessage & return & return & logDebug & return & return & extractedDebug

set debugFilePath to homeDir & "/Desktop/timedeck_debug.txt"
do shell script "printf '%s' " & quoted form of fullDebug & " > " & quoted form of debugFilePath

-- Clean up
do shell script "rm -f " & quoted form of logFilePath
