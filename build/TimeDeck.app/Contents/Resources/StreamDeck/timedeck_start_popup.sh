#!/bin/bash

# TimeDeck StreamDeck Script - Start Activity with Popup Input
# This script always shows a dialog to get the activity name from the user

echo "🎯 TimeDeck - Start Activity with Popup"

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

# Show input dialog to get activity name
activity_name=$(show_input_dialog)

# Check if user cancelled or entered empty name
if [ -z "$activity_name" ]; then
    echo "❌ Cancelled or no activity name provided"
    # Show a brief notification that it was cancelled
    osascript -e 'display notification "Activity start cancelled" with title "TimeDeck"'
    exit 1
fi

echo "▶️ Starting activity: $activity_name"

# URL encode the activity name for spaces and special characters
# Try python3 first, fallback to simple replacement
if command -v python3 >/dev/null 2>&1; then
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$activity_name'))")
else
    # Simple fallback: replace spaces with %20
    encoded_name=$(echo "$activity_name" | sed 's/ /%20/g')
fi

# Start the activity
open "timedeck://start/$encoded_name"

echo "✅ Activity '$activity_name' started successfully!"

# Show success notification
osascript -e "display notification \"Started tracking '$activity_name'\" with title \"TimeDeck\""
