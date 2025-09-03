# TimeDeck - Activity Tracking for Mac

A beautiful and intuitive activity tracking system with a native Mac menu bar app featuring custom icons for granular time tracking throughout your day.

## 🚀 Quick Start

### Professional DMG Installer (Recommended)
1. Download `TimeDeck-0.0.2.dmg`
2. Open the DMG and drag `TimeDeck.app` to Applications
3. Launch TimeDeck from Applications or Spotlight
4. Your custom menu bar icon appears automatically
5. Start tracking activities immediately - no setup required!

### Manual Development Setup
```bash
# Clone and build
./build_app.sh

# Run the app
open build/TimeDeck.app

# Or compile directly
swiftc -o TimeDeck TimeDeck.swift && ./TimeDeck
```

## 📁 Project Structure

**Core Application:**
- `TimeDeck.swift` - Native Swift menu bar app with custom icons
- `build_app.sh` - Build script for development
- `create_dmg.sh` - DMG distribution builder

**AppleScript Functions:**
- `NewActivity.applescript` - Log a new activity with timestamp
- `EndActivity.applescript` - End current activity without starting new one
- `EndDay.applescript` - Calculate and display daily time summary
- `GenerateReport.applescript` - Create detailed multi-day reports
- `StartFresh.applescript` - Clear all activity data

**Icons & Assets:**
- `assets/` - Source icons (App Icon.png, Menubar Icon.png, TimeDeck.psd)
- `icons/` - Generated icons (TimeDeck.icns, menu bar icons, etc.)
- `convert_icons.sh` - Convert source icons to all required formats

**Distribution:**
- `create_timedeck_dmg.sh` - Build professional DMG installer
- `TimeDeck-1.0.0.dmg` - Ready-to-distribute Mac app

**Generated Files:**
- `~/Desktop/timedeck_log.txt` - Activity data (created automatically)
- `~/Desktop/timedeck_report.txt` - Generated reports

## ✨ Features

### Menu Bar App
- **Custom icons** - Professional design using your provided assets
- **Live activity tracking** - See current activity and duration in real-time
- **Configurable shortcuts** - Customize global hotkeys to your preference
- **Preferences system** - User-friendly configuration interface
- **Native Mac experience** - Proper app bundle with metadata
- **Auto-start capability** - Add to Login Items for automatic startup
- **Intuitive interface** - Click menu bar icon to access all functions

### Activity Tracking
- **Granular logging** - Track activities as you switch between tasks
- **Smart time calculation** - Automatic duration tracking between activities
- **Explicit activity ending** - End activities for breaks without starting new ones
- **Daily summaries** - Comprehensive end-of-day time breakdowns
- **Multi-day reports** - Detailed analysis across multiple days
- **Data persistence** - Simple text format for easy backup and analysis

### Additional Integrations
- **StreamDeck support** - Use AppleScript files with StreamDeck buttons
- **Terminal access** - Run scripts directly from command line
- **Cross-platform scripts** - AppleScript files work independently

## 🎯 How to Use

### Menu Bar App (Primary Method)
1. Launch TimeDeck from Applications
2. Click the TimeDeck icon in your menu bar
3. Select "New Activity" and enter activity name
4. Work on your activity (duration tracked automatically)
5. Use "End Activity" for breaks or "New Activity" to switch tasks
6. Generate daily summaries with "End Day Summary"

### Menu Functions
**Click menu items to access:**
- New Activity - Start tracking a new activity
- End Activity - Stop current activity
- End Day Summary - Generate daily summary
- Generate Report - Create detailed report
- About - Version and author information

### StreamDeck Integration 🎮

TimeDeck works perfectly with Stream Deck! Both the Python and Swift versions use the same AppleScript files.

#### **Setup Instructions:**

1. **Add System → Open** action in Stream Deck
2. **Choose "Application"** and enter:
   - **App:** `/usr/bin/osascript`
   - **Arguments:** See examples below

#### **Stream Deck Button Examples:**

**📝 New Activity Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/NewActivity.applescript "Meeting with Team"
```

**⏹️ End Activity Button:**
```
App: /usr/bin/osascript  
Arguments: /Applications/TimeDeck.app/Contents/Scripts/EndActivity.applescript
```

**📊 End Day Summary Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/EndDay.applescript
```

**📈 Generate Report Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/GenerateReport.applescript
```

**🗑️ Start Fresh Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/StartFresh.applescript
```

#### **Dynamic Activity Names:**
For dynamic activities, create multiple buttons with different activity names:
- "📞 Client Call" → `NewActivity.applescript "Client Call"`
- "💻 Development" → `NewActivity.applescript "Development"`  
- "📧 Email" → `NewActivity.applescript "Email"`
- "☕ Break" → `NewActivity.applescript "Break"`

#### **Compatibility:**
- ✅ **Native TimeDeck DMG** (`TimeDeck-0.0.2.dmg`)
- ✅ **All installations** use identical AppleScript paths
- ✅ **Works with any TimeDeck version**

### Terminal Usage (Development/Testing)
```bash
# Test AppleScript files directly
osascript NewActivity.applescript "Meeting with team"
osascript EndActivity.applescript
osascript EndDay.applescript
osascript GenerateReport.applescript
osascript StartFresh.applescript

# Test from installed app location
osascript /Applications/TimeDeck.app/Contents/Scripts/NewActivity.applescript "Development"
osascript /Applications/TimeDeck.app/Contents/Scripts/EndActivity.applescript
```

## 📊 Data Format

Activity data is stored in `~/Desktop/timedeck_log.txt`:
```
1703123456 Meeting with team
1703125678 Code review
1703126890 END
1703127890 Development work
1703129000 END
```

Format: `[UNIX_TIMESTAMP] [ACTIVITY_NAME_OR_END]`

## 🔧 Development

### Building DMG
```bash
# Convert new icons (if assets/ changed)
./convert_icons.sh

# Build professional DMG installer
./create_timedeck_dmg.sh
```

### Icon Management
- Place source icons in `assets/` folder
- Run `./convert_icons.sh` to generate all required formats
- App icon: High-resolution PNG for app bundle and Dock
- Menu bar icon: Optimized for 22px menu bar display

### About Dialog

Access version and author information:
- Click "About" in the TimeDeck menu
- Shows version 0.0.2 and author: Jeremy Roberts
- Lists all available menu shortcuts

### Requirements
- **macOS 10.14+** for native app
- **Swift** for development (Xcode command line tools)
- **No external dependencies** - pure native Mac app

## 💡 Tips

- **Activity names:** Use descriptive names for better tracking
- **Break tracking:** Use "End Activity" for accurate break time
- **Regular reports:** Generate weekly reports for time analysis
- **Backup data:** Log file is plain text for easy backup
- **Login startup:** Add TimeDeck.app to Login Items for auto-start

## 📦 Distribution

**For End Users:**
- Share `TimeDeck-0.0.2.dmg`
- Users drag to Applications and launch
- Native Mac app experience, no dependencies

**For Developers:**
- Fork/clone repository
- Run `./create_dmg.sh` to build
- Customize icons in `assets/` folder
- Pure Swift - no external dependencies

---

**TimeDeck** - Beautiful, professional time tracking for Mac 🎯