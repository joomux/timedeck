-- Debug the exact parsing logic from ActivityStatus

set homeDir to do shell script "echo $HOME"
set logFilePath to homeDir & "/Desktop/timedeck_log.txt"

-- Read log file (same as ActivityStatus)
set logContents to do shell script "cat " & quoted form of logFilePath
set logLines to paragraphs of logContents

-- Get last line (same as ActivityStatus)
set lastLine to item -1 of logLines

-- Parse timestamp (same as ActivityStatus)
set spaceIndex to offset of " " in lastLine
set lastTimestamp to text 1 thru (spaceIndex - 1) of lastLine
set lastActivity to text (spaceIndex + 1) thru -1 of lastLine

-- Build debug output
set debugOutput to "Parsing Debug:" & return & return
set debugOutput to debugOutput & "Last line: '" & lastLine & "'" & return
set debugOutput to debugOutput & "Space index: " & spaceIndex & return
set debugOutput to debugOutput & "Extracted timestamp: '" & lastTimestamp & "'" & return
set debugOutput to debugOutput & "Extracted activity: '" & lastActivity & "'" & return
set debugOutput to debugOutput & "Timestamp class: " & (class of lastTimestamp) & return & return

-- Test the exact date command construction (same as ActivityStatus)
set dateCommand to "date -r " & (lastTimestamp as string) & " +%H:%M"
set debugOutput to debugOutput & "Date command: '" & dateCommand & "'" & return

try
    set dateResult to do shell script dateCommand
    set debugOutput to debugOutput & "Date result: '" & dateResult & "'" & return
on error errMsg
    set debugOutput to debugOutput & "Date error: '" & errMsg & "'" & return
end try

-- Write to file
set debugFilePath to homeDir & "/Desktop/parse_debug.txt"
do shell script "printf '%s' " & quoted form of debugOutput & " > " & quoted form of debugFilePath

display dialog "Parse debug complete! Check ~/Desktop/parse_debug.txt" buttons {"OK"}
