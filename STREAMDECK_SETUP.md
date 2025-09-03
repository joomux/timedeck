# 🎮 TimeDeck + Stream Deck Quick Setup Guide

## 🚀 **Quick Start**

1. Install TimeDeck from DMG to `/Applications/`
2. In Stream Deck Software, add **"System → Open"** actions
3. Configure each button with the settings below

## 📋 **Copy-Paste Button Configurations**

### **📝 New Activity Buttons**

**Meeting Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/NewActivity.applescript "Meeting"
```

**Development Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/NewActivity.applescript "Development"
```

**Email Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/NewActivity.applescript "Email"
```

**Client Work Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/NewActivity.applescript "Client Work"
```

**Break Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/NewActivity.applescript "Break"
```

### **⏹️ Control Buttons**

**End Activity Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/EndActivity.applescript
```

**End Day Summary Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/EndDay.applescript
```

**Generate Report Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/GenerateReport.applescript
```

**Start Fresh Button:**
```
App: /usr/bin/osascript
Arguments: /Applications/TimeDeck.app/Contents/Scripts/StartFresh.applescript
```

## 🎯 **Pro Tips**

- **Custom Activities:** Change `"Meeting"` to any activity name you want
- **Icons:** Use Stream Deck's built-in icons or custom ones
- **Folders:** Organize buttons in Stream Deck folders by project/client
- **Multi-Actions:** Combine `EndActivity` + `NewActivity` for quick switching

## ✅ **Works With TimeDeck**
- Native Mac app: `TimeDeck-0.0.2.dmg`  
- Pure Swift implementation
- No external dependencies required!

## 🗂️ **Common Activity Examples**
- "Meeting with [Client Name]"
- "Development - [Project Name]"
- "Email and Admin"
- "Research"
- "Documentation"
- "Code Review"
- "Planning"
- "Break"
- "Lunch"

## 📊 **Files Created**
- `~/Desktop/timedeck_log.txt` - Activity log
- `~/Desktop/timedeck_report.txt` - Generated reports
