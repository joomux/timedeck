#!/bin/bash
# <bitbar.title>Hacktivity</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Jeremy Roberts</bitbar.author>
# <bitbar.author.github>your-github-username</bitbar.author.github>
# <bitbar.desc>Activity tracking menu bar app</bitbar.desc>
# <bitbar.image>http://www.hosted-somewhere/pluginimage</bitbar.image>
# <bitbar.dependencies>osascript</bitbar.dependencies>
# <bitbar.abouturl>http://url-to-about-page/</bitbar.abouturl>

# Set the base directory for scripts
SCRIPT_DIR="/Users/jeremyroberts/Projects/hacktivity"

echo "📊 Hacktivity"
echo "---"

# Check if we have a current activity
if [ -f ~/Desktop/hacktivity_log.txt ]; then
    last_line=$(tail -n 1 ~/Desktop/hacktivity_log.txt)
    if [[ ! "$last_line" == *"END"* ]]; then
        activity_name=$(echo "$last_line" | cut -d' ' -f2-)
        timestamp=$(echo "$last_line" | cut -d' ' -f1)
        current_time=$(date +%s)
        duration=$((current_time - timestamp))
        hours=$((duration / 3600))
        minutes=$(((duration % 3600) / 60))
        echo "🟢 Current: $activity_name (${hours}h ${minutes}m)"
        echo "---"
    fi
fi

echo "📝 New Activity | bash='osascript \"$SCRIPT_DIR/NewActivity.applescript\"' terminal=false"
echo "⏹️ End Activity | bash='osascript \"$SCRIPT_DIR/EndActivity.applescript\"' terminal=false"
echo "---"
echo "📈 End Day Summary | bash='osascript \"$SCRIPT_DIR/EndDay.applescript\"' terminal=false"
echo "📋 Generate Report | bash='osascript \"$SCRIPT_DIR/GenerateReport.applescript\"' terminal=false"
echo "---"
echo "🗑️ Start Fresh | bash='osascript \"$SCRIPT_DIR/StartFresh.applescript\"' terminal=false"
echo "---"
echo "📁 Open Log File | bash='open ~/Desktop/hacktivity_log.txt' terminal=false"
echo "📄 Open Report File | bash='open ~/Desktop/hacktivity_report.txt' terminal=false"
