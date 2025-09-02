# TimeDeck - Activity Tracking for Mac

A beautiful and intuitive activity tracking system with a native Mac menu bar app featuring custom icons for granular time tracking throughout your day.

## 🚀 Quick Start

### Professional DMG Installer (Recommended)
1. Download `TimeDeck-1.0.0.dmg`
2. Open the DMG and drag `TimeDeck.app` to Applications
3. Launch TimeDeck from Applications or Spotlight
4. Your custom menu bar icon appears automatically
5. Dependencies install automatically on first run

### Manual Development Setup
```bash
# Clone and run
python3 timedeck_menubar.py

# Or use the launch script
./launch_menubar.sh
```

## 📁 Project Structure

**Core Application:**
- `timedeck_menubar.py` - Main menu bar app with custom icons
- `launch_menubar.sh` - Launch script for development
- `requirements.txt` - Python dependencies (rumps)

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

### StreamDeck Integration (Optional)
Configure StreamDeck buttons to run AppleScript files:
- **App:** `/usr/bin/osascript`
- **Arguments:** `/path/to/NewActivity.applescript "Activity Name"`

### Terminal Usage (Development)
```bash
# Log activities
osascript NewActivity.applescript "Meeting with team"
osascript EndActivity.applescript

# Generate reports
osascript EndDay.applescript
osascript GenerateReport.applescript

# Manage data
osascript StartFresh.applescript
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

### Requirements
- **macOS 10.14+** for app bundle
- **Python 3.8+** for development
- **rumps** for menu bar functionality (auto-installed)

## 💡 Tips

- **Activity names:** Use descriptive names for better tracking
- **Break tracking:** Use "End Activity" for accurate break time
- **Regular reports:** Generate weekly reports for time analysis
- **Backup data:** Log file is plain text for easy backup
- **Login startup:** Add TimeDeck.app to Login Items for auto-start

## 📦 Distribution

**For End Users:**
- Share `TimeDeck-1.0.0.dmg`
- Users drag to Applications and launch
- Professional Mac installer experience

**For Developers:**
- Fork/clone repository
- Run `./create_timedeck_dmg.sh` to build
- Customize icons in `assets/` folder

---

**TimeDeck** - Beautiful, professional time tracking for Mac 🎯