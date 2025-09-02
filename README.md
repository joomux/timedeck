# Hacktivity - Activity Tracking for StreamDeck

A simple AppleScript-based activity tracking system designed to work with StreamDeck for granular time tracking throughout your day.

## Files

- `NewActivity.applescript` - Logs a new activity with timestamp
- `EndActivity.applescript` - Ends the current activity without starting a new one
- `EndDay.applescript` - Calculates and displays time spent on each activity for the current day
- `GenerateReport.applescript` - Creates detailed multi-day reports with activity sessions
- `StartFresh.applescript` - Clears all activity data to start fresh
- `hacktivity_log.txt` - Data file (created automatically on Desktop)
- `hacktivity_report.txt` - Generated report file (created on Desktop)

## Setup

### For StreamDeck

1. **New Activity Action:**
   - Add a "System > Open" action to your StreamDeck
   - Set the app to: `/usr/bin/osascript`
   - Set arguments to: `/Users/jeremyroberts/Projects/hacktivity/NewActivity.applescript "Activity Name"`
   - Or for prompted input: `/Users/jeremyroberts/Projects/hacktivity/NewActivity.applescript`

2. **End Activity Action:**
   - Add a "System > Open" action to your StreamDeck
   - Set the app to: `/usr/bin/osascript`
   - Set arguments to: `/Users/jeremyroberts/Projects/hacktivity/EndActivity.applescript`

3. **End Day Action:**
   - Add a "System > Open" action to your StreamDeck
   - Set the app to: `/usr/bin/osascript`
   - Set arguments to: `/Users/jeremyroberts/Projects/hacktivity/EndDay.applescript`

4. **Generate Report Action:**
   - Add a "System > Open" action to your StreamDeck
   - Set the app to: `/usr/bin/osascript`
   - Set arguments to: `/Users/jeremyroberts/Projects/hacktivity/GenerateReport.applescript`

5. **Start Fresh Action:**
   - Add a "System > Open" action to your StreamDeck
   - Set the app to: `/usr/bin/osascript`
   - Set arguments to: `/Users/jeremyroberts/Projects/hacktivity/StartFresh.applescript`

### Manual Usage

You can also run the scripts directly from Terminal:

```bash
# Log a new activity with name
osascript NewActivity.applescript "Meeting with team"

# Log a new activity with prompt
osascript NewActivity.applescript

# End current activity without starting a new one
osascript EndActivity.applescript

# Generate end of day summary
osascript EndDay.applescript

# Generate detailed multi-day report
osascript GenerateReport.applescript

# Clear all activity data to start fresh
osascript StartFresh.applescript
```

## How It Works

### New Activity
- Accepts an optional activity name as an argument
- If no argument provided, prompts user for input
- Logs entry to `~/Desktop/hacktivity_log.txt` in format: `timestamp activity_name`
- Shows notification confirming the activity was logged

### End Activity
- Ends the current activity without starting a new one
- Logs an "END" marker with timestamp
- Useful for breaks, lunch, or end of work sessions
- Shows notification confirming the activity was ended

### End Day
- Automatically ends any currently open activity with an END marker
- Reads all entries from the log file
- Filters entries for the current day
- Calculates time spent on each activity by measuring intervals between activity switches and END markers
- Handles explicit activity endings for accurate time tracking
- Displays a summary dialog with:
  - Time spent on each activity (hours, minutes, seconds)
  - Total tracked time for the day

### Generate Report
- Analyzes ALL activity data in the log file (not just today)
- Groups activities by date and calculates individual activity sessions
- Creates a detailed text report showing:
  - Date and day of week for each day
  - Start time, duration, and activity name for each session
  - Daily totals and overall summary statistics
- Saves report to `~/Desktop/hacktivity_report.txt`
- Perfect for weekly reviews and time analysis

### Start Fresh
- Prompts user for confirmation before clearing data
- Clears all activity data from the log file
- Useful for starting new tracking periods or clearing old data
- Shows confirmation notifications

## Data Format

The log file (`hacktivity_log.txt`) stores entries in this format:
```
1703123456 Meeting with team
1703125678 Code review
1703126890 END
1703127890 Development work
1703129000 END
```

Where the first number is a UNIX timestamp and the rest is either the activity name or "END" to mark the end of the current activity.

## Features

- **Granular tracking**: Log activities throughout the day as you switch between tasks
- **Explicit activity ending**: End activities without starting new ones (perfect for breaks)
- **Automatic calculations**: End Day script automatically calculates time spent on each activity
- **Detailed reporting**: Generate comprehensive multi-day reports with session-by-session breakdowns
- **StreamDeck integration**: Designed to work seamlessly with StreamDeck buttons
- **Simple data format**: Plain text file for easy backup and analysis
- **Handles repeated activities**: If you return to an activity later in the day, time is accumulated
- **Start fresh capability**: Clear all data to begin new tracking periods
- **User-friendly**: Shows notifications and clear dialog boxes with confirmation prompts

## Tips

- Use descriptive activity names for better tracking
- Log activities as you switch between them for accurate time tracking
- Use "End Activity" when taking breaks or ending work sessions for accurate time tracking
- Run "Generate Report" weekly or every few days for detailed time analysis
- The last activity of the day is assumed to continue until you run "End Day" (unless explicitly ended)
- Log file is stored on Desktop for easy access and backup
- Generated reports are also saved on Desktop for easy review and archiving
