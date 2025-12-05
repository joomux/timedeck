# 🎮 StreamDeck + TimeDeck Integration Guide

**The EASY way to control TimeDeck from your StreamDeck!**

No custom plugins required - uses StreamDeck's built-in "System > Open" controls with TimeDeck URL schemes.

## 🚀 Quick Setup

### Step 1: Make sure TimeDeck is Running
- TimeDeck app should be running in menu bar
- URL scheme is registered automatically

### Step 2: Add StreamDeck Actions
1. **Open StreamDeck software**
2. **Drag "System > Open"** from actions to a button
3. **Configure the URL** (see commands below)
4. **Customize button** (title, icon, etc.)
5. **Test it!**

## 📋 Available TimeDeck URL Commands

### 🎯 **Start Activities**
```
timedeck://start/Development
timedeck://start/Meeting  
timedeck://start/Email
timedeck://start/Break
timedeck://new/Custom%20Activity%20Name
```

### ⏹️ **Control Activities**
```
timedeck://end          # End current activity
timedeck://pause        # Pause/resume activity  
timedeck://status       # Show current status
```

### 🛠️ **Utilities**
```
timedeck://report       # Generate activity report
timedeck://fresh        # Start fresh (clear logs)
timedeck://templates    # Open template manager
```

## 🚀 **Quick Setup for Distributed Apps**

### **Step 1: Install StreamDeck Scripts**
1. **Open TimeDeck menu** (click menu bar icon)
2. **Go to Tools** → **"🎮 Install StreamDeck Scripts"**
3. **Click "Open Folder"** to see installed scripts
4. **Scripts are now available** at `~/Library/Application Support/TimeDeck/StreamDeck/`

### **Step 2: Configure StreamDeck Buttons**
Use these scripts with StreamDeck "System > Open" action:

## 🎮 StreamDeck Button Examples

### **Example 1: End Activity**
- **Action:** System > Open
- **App/File:** `~/Library/Application Support/TimeDeck/StreamDeck/timedeck_end.sh`
- **Title:** "⏹️ End"
- **Icon:** Stop button

### **Example 2: Show Status**
- **Action:** System > Open
- **App/File:** `~/Library/Application Support/TimeDeck/StreamDeck/timedeck_status.sh`
- **Title:** "📊 Status"
- **Icon:** Chart/status icon

### **Example 3: Start Activity (Interactive)**
- **Action:** System > Open
- **App/File:** `~/Library/Application Support/TimeDeck/StreamDeck/timedeck_start_interactive.sh`
- **Title:** "🚀 Start"
- **Icon:** Play button
- **Note:** Shows menu of your templates to choose from

### **Example 4: Open Template Manager**
- **Action:** System > Open
- **App/File:** `~/Library/Application Support/TimeDeck/StreamDeck/timedeck_templates.sh`
- **Title:** "📝 Templates"
- **Icon:** Settings/template icon

## 🎯 **Simple & Streamlined Scripts**

### **Available Scripts After Installation:**
```
timedeck_end.sh                    # End current activity
timedeck_status.sh                 # Show activity status  
timedeck_templates.sh              # Open template manager
timedeck_start_interactive.sh      # Start activity (shows menu of your templates)
timedeck_start.sh                  # Start activity (advanced - requires argument)
```

### **How the Interactive Start Works:**
The `timedeck_start_interactive.sh` script:
1. **Connects to TimeDeck** via HTTP API
2. **Fetches your current templates** automatically
3. **Shows numbered menu** to choose activity
4. **Starts selected activity** immediately

**Example interaction:**
```
🎯 TimeDeck - Start Activity
==========================
Available activities:
-------------------
1. Development
2. Meeting  
3. Email
4. Break
5. Planning

0. Cancel

Select activity (number): 2
🚀 Starting activity: Meeting
```

### **For Advanced Users:**
Use `timedeck_start.sh "Activity Name"` for direct scripting or automation.

## 🏗️ **StreamDeck Setup Walkthrough**

### **Adding Your First TimeDeck Button:**

1. **Open StreamDeck software**

2. **Find "System" category** in the right panel
   - Look for "System" folder
   - Drag "Open" action to an empty button

3. **Configure the button:**
   - **URL field:** Enter `timedeck://start/Development`  
   - **Title:** Enter "💻 Dev"
   - **Optional:** Choose custom icon

4. **Test it:**
   - Press the StreamDeck button
   - Should see TimeDeck notification: "🚀 StreamDeck - Started 'Development'"
   - Check TimeDeck menu bar - should show active activity

5. **Add more buttons:**
   - Repeat for other activities
   - Create End, Pause, Status buttons
   - Customize with icons and titles

## 📊 **Recommended StreamDeck Layout**

```
┌─────────────┬─────────────┬─────────────┐
│ 💻 Dev      │ 🗣️ Meeting  │ 📧 Email    │
│ timedeck:// │ timedeck:// │ timedeck:// │
│ start/Dev   │ start/Meet  │ start/Email │
├─────────────┼─────────────┼─────────────┤
│ ☕ Break    │ 🍽️ Lunch    │ ⏹️ End      │
│ timedeck:// │ timedeck:// │ timedeck:// │
│ start/Break │ start/Lunch │ end         │
├─────────────┼─────────────┼─────────────┤
│ ⏸️ Pause    │ 📊 Status   │ 🧹 Fresh    │
│ timedeck:// │ timedeck:// │ timedeck:// │
│ pause       │ status      │ fresh       │
└─────────────┴─────────────┴─────────────┘
```

## 🎨 **Customization Tips**

### **Button Titles:**
- Keep short (8-10 characters max)
- Use emojis for visual appeal
- Examples: "💻 Dev", "⏹️ End", "📊 Status"

### **Icons:**
- Use StreamDeck's built-in icons
- Or download custom icons (72x72 PNG)
- Match icon to activity type

### **Organization:**
- Group similar activities together
- Put frequently used buttons in easy reach
- Use folders for less common commands

## 🔧 **Advanced Usage**

### **URL Encoding for Special Characters:**
If your activity names have spaces or special characters:
```
timedeck://start/My%20Custom%20Activity
timedeck://start/Project%20Alpha%20Beta
```

### **Query Parameters (Alternative):**
```
timedeck://start?activity=My Custom Activity
```

### **Template Integration:**
Use your existing TimeDeck templates:
```
timedeck://start/Development    # If you have a "Development" template
timedeck://start/Planning       # If you have a "Planning" template  
```

## ✅ **Troubleshooting**

### **Button doesn't work?**
1. **Check TimeDeck is running** - Look for menu bar icon
2. **Test URL in browser** - Try `timedeck://status` in Safari
3. **Check spelling** - URLs are case-sensitive
4. **Restart StreamDeck** if needed

### **No notification appears?**
1. **Check System Preferences** > Notifications > TimeDeck
2. **Enable notifications** if disabled
3. **Test with** `timedeck://status` - should show popup

### **Activity not starting?**  
1. **Try simpler name** - Use `timedeck://start/Test`
2. **Check URL encoding** - Spaces should be `%20`
3. **View TimeDeck menu** - Should show current activity

## 🚀 **Pro Tips**

### **Multi-Action Buttons:**
Create StreamDeck "Multi Actions" to:
1. End current activity
2. Start new activity  
3. Show status

### **Folder Organization:**
```
📁 TimeDeck/
  ├── 🎯 Work Activities/
  │   ├── 💻 Development
  │   ├── 🗣️ Meetings
  │   └── 📧 Email
  ├── 🎮 Controls/
  │   ├── ⏹️ End
  │   ├── ⏸️ Pause
  │   └── 📊 Status
  └── 🛠️ Utilities/
      ├── 🧹 Fresh Start
      └── 📄 Report
```

### **Integration with Other Tools:**
- **OBS Studio:** Start "Streaming" activity when going live
- **Zoom:** Start "Meeting" activity when joining calls  
- **Focus modes:** Start "Focus" activity with Do Not Disturb

## 🎉 **You're All Set!**

**That's it!** You now have full StreamDeck integration with TimeDeck using native URL schemes.

**Benefits of this approach:**
- ✅ **No custom plugins** required
- ✅ **Works immediately** with any StreamDeck
- ✅ **Built-in StreamDeck features** (icons, folders, etc.)
- ✅ **Reliable and fast** 
- ✅ **Easy to customize** and extend

**Happy time tracking!** 🎯