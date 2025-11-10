# Pause/Resume Feature Documentation

## Overview
The pause/resume feature allows you to temporarily pause an active task and resume it later. Only one active task can exist at a time.

## How to Use

### Via URL Scheme (StreamDeck)
- **Pause/Resume Toggle**: `timedeck://pause` or `timedeck://resume`
  - Both URLs do the same thing - toggle between paused and active state
  - If activity is active → pauses it
  - If activity is paused → resumes it

### Via Menu Bar
- Click the TimeDeck menu bar icon
- Select "⏸️ Pause Activity" to pause
- Select "▶️ Resume Activity" to resume

### Via HTTP API (StreamDeck Plugin)
```bash
curl -X POST http://localhost:8765/activities/pause
```

## Visual Indicators

### Menu Bar Title
- Active: `Development (1:23)`
- Paused: `Development ⏸️ (1:23)`

### Menu Items
- Current activity shows pause state: `🎯 Current: Development ⏸️`
- Menu button changes:
  - When active: "⏸️ Pause Activity"
  - When paused: "▶️ Resume Activity"

## Behavior

### When Pausing
- Logs a "pause" event in the activity log
- Shows notification: "⏸️ Paused - Taking a break from [Activity]"
- Timer continues running (pause time is logged separately)
- UI updates to show pause indicator

### When Resuming
- Logs a "resume" event in the activity log
- Shows notification: "▶️ Resumed - Back to [Activity]"
- Removes pause indicator from UI
- Activity timer continues

### When No Activity is Active
- Shows helpful notification: "⚠️ No Active Activity - Start an activity first before pausing"
- Uses fallback to alert if notifications are disabled

## Implementation Details

### Key Files Modified
- `ActivityTracker.swift`: Enhanced `pauseResumeActivity()` with better error handling
- `TimeDeckApp.swift`: Updated UI to show pause state in menu bar and menu items

### State Management
- State is stored in `ActivityTracker.isInBreak` (boolean)
- Only one activity can be active at a time (enforced by `startActivity()`)
- Pause state is preserved across menu rebuilds and UI updates

### Data Logging
- Pause events: `dataManager.logActivity(.pause, activityName: currentActivity)`
- Resume events: `dataManager.logActivity(.resume, activityName: currentActivity)`
- Both events are timestamped and stored in the activity log

## Testing

### Manual Test Steps
1. Start an activity: `timedeck://start/Development`
2. Verify it shows in menu bar: `Development (0:01)`
3. Pause it: `timedeck://pause`
4. Verify pause indicator: `Development ⏸️ (0:01)`
5. Resume it: `timedeck://pause` or `timedeck://resume`
6. Verify no pause indicator: `Development (0:02)`
7. Try pausing with no activity: `timedeck://pause`
8. Verify error message: "No Active Activity"

### Expected Notifications
- ✅ "⏸️ Paused - Taking a break from Development"
- ✅ "▶️ Resumed - Back to Development"
- ✅ "⚠️ No Active Activity - Start an activity first before pausing"

## StreamDeck Integration

### Button Setup
1. Open StreamDeck software
2. Add "System > Open" action
3. Set URL to: `timedeck://pause`
4. Set icon to pause/resume symbol
5. Test by clicking button

### Multi-Action Setup (Advanced)
Create a folder with:
- Button 1: Start Activity (`timedeck://start/Development`)
- Button 2: Pause/Resume (`timedeck://pause`)
- Button 3: End Activity (`timedeck://end`)

## Troubleshooting

### Pause doesn't work
1. Ensure TimeDeck app is running (check menu bar for icon)
2. Verify an activity is active before pausing
3. Check Console.app for log messages starting with "⏸️ Toggling pause/resume"

### No notification appears
- Notifications may be disabled in System Preferences
- Fallback alerts will show if notifications fail
- Check: System Preferences > Notifications > TimeDeck

### URL scheme not recognized
1. Rebuild the app: `./build_app.sh`
2. Copy to Applications: `cp -R build/TimeDeck.app /Applications/`
3. Launch the app at least once to register URL scheme
4. Try opening: `open "timedeck://pause"`

## Version History
- **v0.0.4**: Enhanced pause/resume with better error handling and visual indicators
- **v0.0.3**: Initial pause/resume implementation

