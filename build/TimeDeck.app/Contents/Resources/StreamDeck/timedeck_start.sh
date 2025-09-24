#!/bin/bash

# Function to show input dialog and get activity name
show_input_dialog() {
    # Use AppleScript to show a native macOS input dialog
    local activity_name=$(osascript << 'EOF'
tell application "System Events"
    activate
    set activityName to text returned of (display dialog "🎯 Start New Activity" & return & return & "Enter activity name:" default answer "" with title "TimeDeck" buttons {"Cancel", "Start Activity"} default button "Start Activity" with icon note)
    return activityName
end tell
EOF
)
    echo "$activity_name"
}

# Check if activity name was provided as parameter
if [ -z "$1" ]; then
    echo "🎯 TimeDeck - Opening enhanced activity dialog..."
    
    # Use TimeDeck's enhanced dialog instead of simple input
    open "timedeck://dialog"
    
    echo "✅ Enhanced activity dialog opened!"
else
    # Use the provided parameter
    activity_name="$1"
    echo "▶️ Starting activity: $activity_name"
    
    # URL encode the activity name for spaces and special characters
    # Try python3 first, fallback to simple replacement
    if command -v python3 >/dev/null 2>&1; then
        encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$activity_name'))")
    else
        # Simple fallback: replace spaces with %20
        encoded_name=$(echo "$activity_name" | sed 's/ /%20/g')
    fi
    
    open "timedeck://start/$encoded_name"
    
    echo "✅ Activity started successfully!"
fi
