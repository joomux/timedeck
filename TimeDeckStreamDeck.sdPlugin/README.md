# TimeDeck StreamDeck Plugin

Control your TimeDeck activity tracking directly from your Elgato StreamDeck!

## 🚀 Features

### 📝 **Start Activity**
- Start a new TimeDeck activity with custom name
- Configurable activity name through property inspector
- Visual feedback on StreamDeck button

### ⏹️ **End Activity** 
- End the currently running activity
- Shows which activity was ended
- One-click operation

### 📊 **Activity Status**
- Live display of current activity
- Shows elapsed time (updates every 5 seconds)
- Shows pause status
- Displays "No Activity" when nothing is running

### 🏷️ **Quick Template**
- Start activity from your TimeDeck templates
- Loads templates directly from TimeDeck app
- Visual template preview with emoji and category
- Automatically syncs with your TimeDeck configuration

### ⏸️ **Pause/Resume**
- Toggle pause state of current activity
- Visual feedback showing pause/resume status
- Works only when activity is running

### 🧹 **Start Fresh**
- Clear all activity logs and start clean
- Useful for new day/week/project
- Confirmation through visual feedback

## 🔧 Installation

### Prerequisites
- **TimeDeck app** must be running
- **StreamDeck software** version 6.0 or higher
- **macOS 10.14+** or **Windows 10+**

### Install Steps
1. **Double-click** `TimeDeckStreamDeck.streamDeckPlugin` to install
2. **Drag actions** from StreamDeck software to your StreamDeck
3. **Configure** actions using the property inspector
4. **Start tracking!**

## ⚙️ Configuration

### Start Activity Action
1. Drag "Start Activity" to your StreamDeck
2. Configure the activity name in property inspector
3. Use common activities or create custom names

### Quick Template Action  
1. Drag "Quick Template" to your StreamDeck
2. Select from your existing TimeDeck templates
3. Templates sync automatically from TimeDeck app

### Other Actions
- **End Activity**, **Pause/Resume**, **Start Fresh**: No configuration needed
- **Activity Status**: Automatically updates every 5 seconds

## 🌐 API Integration

This plugin communicates with TimeDeck through a local HTTP API:

```
http://localhost:8080/api/
├── /health          # Server status
├── /status          # Current activity status  
├── /templates       # Available templates
├── /activities/start # Start new activity
├── /activities/end   # End current activity
├── /activities/pause # Pause/resume activity
└── /activities/fresh # Start fresh
```

## 🛠️ Development

### Requirements
- Node.js 12.0+
- TimeDeck app running with HTTP API server

### Setup
```bash
cd TimeDeckStreamDeck.sdPlugin
npm install
```

### Testing
1. Enable StreamDeck developer mode
2. Install plugin manually  
3. Check StreamDeck console for logs
4. Test API endpoints: `curl http://localhost:8080/api/health`

## 🐛 Troubleshooting

### Plugin not working?
1. **Check TimeDeck is running** - Look for menu bar icon
2. **Test API**: `curl http://localhost:8080/api/health`
3. **Check StreamDeck logs** - Enable developer mode
4. **Restart StreamDeck software**

### Templates not loading?
1. **Verify TimeDeck templates** exist in the app
2. **Check API**: `curl http://localhost:8080/api/templates`
3. **Refresh plugin** by removing and re-adding action

### Activity Status not updating?
- Status updates every 5 seconds automatically
- Remove and re-add the Activity Status action
- Check TimeDeck API is responding

## 📝 Version History

### v1.0.0
- ✅ Start/End Activity actions
- ✅ Live Activity Status display  
- ✅ Quick Template integration
- ✅ Pause/Resume functionality
- ✅ Start Fresh action
- ✅ HTTP API integration
- ✅ Property inspector configuration

## 🤝 Support

For issues related to:
- **Plugin functionality**: Check TimeDeck app logs
- **StreamDeck integration**: Enable developer mode for debugging  
- **API connectivity**: Verify TimeDeck HTTP server is running on port 8080

Built with ❤️ for productivity enthusiasts!
