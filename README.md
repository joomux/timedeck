# ✨ TimeDeck Enhanced - Next-Level Activity Tracking for Mac

A revolutionary activity tracking system with an enhanced native Mac menu bar app featuring smart templates, intelligent break detection, pomodoro timers, real-time analytics, and much more!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A41LQYP0)

## 🚀 Quick Start

### Professional DMG Installer (Recommended)
1. Build DMG: `./create_dmg.sh`
2. Open the generated DMG and drag `TimeDeck.app` to Applications
3. Launch TimeDeck from Applications or Spotlight
4. Your custom menu bar icon appears automatically
5. Start tracking activities immediately - no setup required!

### Manual Development Setup
```bash
# Clone and build
./build_app.sh

# Run the app
open build/TimeDeck.app

# Or compile directly (run build script instead)
./build_app.sh && open build/TimeDeck.app
```

## 📁 Project Structure

**Core Application:**
- `main.swift` - Application entry point
- `TimeDeckApp.swift` - Main application delegate and UI coordination
- `ActivityTracker.swift` - Activity tracking and logging
- `TemplateManager.swift` - Template management and UI
- `Analytics.swift` - Dashboard, reports, and data export
- `NotificationManager.swift` - Notification handling
- `HTTPServer.swift` - HTTP API for StreamDeck integration
- `DataManager.swift` - Data persistence and management
- `AlertManager.swift` - Centralized alert system
- `ActivityTemplate.swift` - Data models and preferences
- `Extensions.swift` - Utility extensions
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
- `create_dmg.sh` - Build professional DMG installer

**Generated Files:**
- `~/Desktop/timedeck_log.txt` - Activity data (created automatically)
- `~/Desktop/timedeck_report.txt` - Generated reports

## ✨ Enhanced Features

### 🚀 Smart Activity Management
- **Smart Activity Templates** - Pre-configured templates with emojis and colors
- **Quick Action Buttons** - One-click activity switching from menu bar
- **Recent Activity Suggestions** - Intelligent auto-complete based on history
- **Enhanced Activity Dialog** - Beautiful floating window with template selection
- **Activity Categories** - Organize work vs personal activities

### 🧠 Intelligent Automation
- **Break Detection** - Automatic idle time detection with smart handling
- **Pomodoro Timer Integration** - Built-in work/break cycles with notifications
- **Global Keyboard Shortcuts** - System-wide hotkeys (⌘⌥T, ⌘⌥P, ⌘⌥E)
- **Smart Notifications** - Modern notification system with rich content
- **Pause/Resume Functionality** - Intelligent activity state management

### 📊 Advanced Analytics & Insights
- **Real-time Dashboard** - Live analytics with today's and weekly summaries
- **Enhanced Menu Bar Display** - Rich status with activity duration and progress
- **Visual Activity Status** - Color-coded activities and progress indicators
- **Goal Setting & Tracking** - Set daily/weekly targets with progress monitoring
- **Advanced Export Options** - CSV, JSON, and plain text export formats

### 🎨 Beautiful User Experience
- **Enhanced UI Design** - Modern, floating windows with professional layouts
- **Template-based Interface** - Quick selection with visual activity templates
- **Preferences Panel** - Comprehensive settings for all features
- **Template Management** - Add, edit, and organize your activity templates
- **Dark Mode Support** - Automatic adaptation to system appearance

### 🔧 Technical Enhancements
- **Modern Notification System** - UserNotifications framework (macOS 11+)
- **Backward Compatibility** - Supports macOS 10.14+ with graceful fallbacks
- **Enhanced Data Structures** - Robust activity tracking with better parsing
- **Performance Optimizations** - 15-second update cycles for responsive UI
- **Memory Management** - Proper timer cleanup and resource management

### 📱 System Integration
- **Global Event Monitoring** - System-wide keyboard shortcut capture
- **Idle State Detection** - CGEventSource integration for accurate idle detection
- **Application Lifecycle** - Proper startup, shutdown, and state management
- **Preferences Persistence** - UserDefaults integration for settings storage

### 📈 Data & Reporting
- **Multiple Export Formats** - Professional CSV and JSON export capabilities
- **Historical Analysis** - Week-over-week and day-over-day comparisons
- **Activity Categorization** - Work vs personal time breakdown
- **Duration Calculations** - Precise time tracking with multiple format options

### Legacy Features (Enhanced)
- **StreamDeck support** - Use AppleScript files with StreamDeck buttons
- **Terminal access** - Run scripts directly from command line
- **Cross-platform scripts** - AppleScript files work independently
- **Data persistence** - Enhanced text format with backward compatibility

## 🎯 Enhanced Features Guide

### 🚀 Quick Start with Enhanced TimeDeck
1. **Launch TimeDeck Enhanced** from Applications
2. **Grant notification permissions** when prompted for smart alerts
3. **Click the menu bar icon** to see the enhanced menu with quick actions
4. **Try a Quick Action** - Click any emoji button for instant activity start
5. **Use keyboard shortcuts** - ⌘⌥T for new activity, ⌘⌥P to pause/resume

### ✨ New Activity Dialog (Enhanced)
1. **Click "✨ New Activity..."** in the menu or press ⌘⌥T
2. **Choose from Templates** - Click any template button for instant selection
3. **Or type custom name** - Auto-complete will suggest recent activities
4. **Recent Activities** - Quick access to your most used activities
5. **Press Enter or click Start** to begin tracking

### 🚀 Quick Actions Menu
- **One-click activity start** from template buttons in menu
- **Emoji indicators** show activity types at a glance
- **Organized by category** (Work vs Personal activities)
- **Instant switching** - no dialogs needed for common activities

### 🧠 Smart Break Detection
1. **Enable in Preferences** (⌘⌥, or menu → Preferences)
2. **Set idle threshold** (default: 5 minutes)
3. **When idle detected** - choose to log as break, continue, or start new activity
4. **Smart interruption** - won't interrupt during Pomodoro sessions

### 🍅 Pomodoro Timer Integration
1. **Enable Pomodoro** in Preferences
2. **Start Pomodoro** from menu for focused work sessions
3. **Automatic transitions** - work → break → work cycles
4. **Smart notifications** alert you when to switch
5. **Configurable durations** - customize work and break lengths

### 📊 Real-time Dashboard
1. **Click "Daily Dashboard"** or press ⌘⌥D
2. **View today's activities** with precise time breakdowns
3. **Weekly summaries** show productivity patterns
4. **Visual insights** help optimize your time allocation

### ⌨️ Global Keyboard Shortcuts
- **⌘⌥T** - New Activity (works from any app)
- **⌘⌥P** - Pause/Resume current activity
- **⌘⌥E** - End current activity
- **⌘⌥D** - Open Dashboard
- **⌘⌥,** - Open Preferences

### 📈 Enhanced Export & Analytics
1. **Export Data** from menu for external analysis
2. **Choose format** - CSV for spreadsheets, JSON for developers
3. **Historical tracking** across days, weeks, and months
4. **Goal setting** to track productivity targets

### 🎨 Customization Options
1. **Manage Templates** - add, edit, or remove activity templates
2. **Set Goals** - configure daily and weekly time targets
3. **Preferences Panel** - fine-tune all enhanced features
4. **Template colors** and emojis for visual organization

### Legacy Menu Functions (Enhanced)
**Enhanced menu organization:**
- **🚀 Quick Actions** - Template-based instant activity start
- **✨ New Activity...** - Enhanced dialog with suggestions
- **⏹️ End Activity** - Smart activity termination
- **⏸️ Pause/Resume** - Intelligent pause/resume toggle
- **🍅 Pomodoro** - Timer controls (when enabled)
- **📊 Analytics & Reports** - Dashboard, status, summaries, exports
- **🔧 Tools** - Templates, goals, preferences, fresh start
- **About TimeDeck Enhanced** - Feature overview and shortcuts

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
- ✅ **Native TimeDeck DMG** (`TimeDeck-0.0.3.dmg`)
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
./create_dmg.sh
```

### Icon Management
- Place source icons in `assets/` folder
- Run `./convert_icons.sh` to generate all required formats
- App icon: High-resolution PNG for app bundle and Dock
- Menu bar icon: Optimized for 22px menu bar display

### About Dialog

Access version and author information:
- Click "About" in the TimeDeck menu
- Shows version 0.0.3 and author: Jeremy Roberts
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
- Run `./create_dmg.sh` to build distribution DMG
- Share the generated DMG file
- Users drag to Applications and launch
- Native Mac app experience, no dependencies

**For Developers:**
- Fork/clone repository
- Run `./build_app.sh` for development builds
- Run `./create_dmg.sh` to build distribution DMG
- Customize icons in `assets/` folder
- Pure Swift - no external dependencies

---

**TimeDeck** - Beautiful, professional time tracking for Mac 🎯