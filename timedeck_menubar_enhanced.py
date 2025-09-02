#!/usr/bin/env python3
"""
TimeDeck Menu Bar App with Keyboard Shortcuts
A menu bar application for quick access to TimeDeck scripts with global hotkeys
"""

import rumps
import subprocess
import os
import time
import threading
from pathlib import Path

# Try to import keyboard for global hotkeys (optional)
try:
    import keyboard
    GLOBAL_HOTKEYS_AVAILABLE = True
except ImportError:
    GLOBAL_HOTKEYS_AVAILABLE = False

class TimeDeckApp(rumps.App):
    def __init__(self):
        # Try to use custom icon, fallback to emoji
        icon_path = Path(__file__).parent / "icons" / "menubar_icon.png"
        if icon_path.exists():
            super(TimeDeckApp, self).__init__(str(icon_path), title="TimeDeck")
        else:
            super(TimeDeckApp, self).__init__("📊", title="TimeDeck")
        
        # Set up paths
        self.script_dir = Path(__file__).parent
        self.log_file = Path.home() / "Desktop" / "timedeck_log.txt"
        self.report_file = Path.home() / "Desktop" / "timedeck_report.txt"
        
        # Set up menu items with keyboard shortcuts
        self.menu = [
            "Current Activity",
            None,  # Separator
            rumps.MenuItem("New Activity", key="n"),
            rumps.MenuItem("End Activity", key="e"), 
            None,  # Separator
            rumps.MenuItem("End Day Summary", key="d"),
            rumps.MenuItem("Generate Report", key="r"),
            None,  # Separator
            "Start Fresh",
            None,  # Separator
            "Open Log File",
            "Open Report File",
            None,  # Separator
            "Keyboard Shortcuts" if GLOBAL_HOTKEYS_AVAILABLE else "Menu Shortcuts Only"
        ]
        
        # Update title with current activity info
        self.update_title()
        
        # Set up timer to update every 30 seconds
        self.timer = rumps.Timer(self.update_title, 30)
        self.timer.start()
        
        # Set up global hotkeys if available
        if GLOBAL_HOTKEYS_AVAILABLE:
            self.setup_global_hotkeys()
    
    def setup_global_hotkeys(self):
        """Set up global keyboard shortcuts"""
        try:
            # Global hotkeys (Cmd+Shift+combination)
            keyboard.add_hotkey('cmd+shift+n', self.hotkey_new_activity)
            keyboard.add_hotkey('cmd+shift+e', self.hotkey_end_activity)
            keyboard.add_hotkey('cmd+shift+d', self.hotkey_end_day)
            print("Global hotkeys enabled:")
            print("  Cmd+Shift+N - New Activity")
            print("  Cmd+Shift+E - End Activity") 
            print("  Cmd+Shift+D - End Day Summary")
        except Exception as e:
            print(f"Could not set up global hotkeys: {e}")
    
    def hotkey_new_activity(self):
        """Global hotkey handler for new activity"""
        # Run in main thread
        rumps.notification("TimeDeck", "Hotkey Pressed", "Cmd+Shift+N - New Activity")
        self.new_activity(None)
    
    def hotkey_end_activity(self):
        """Global hotkey handler for end activity"""
        rumps.notification("TimeDeck", "Hotkey Pressed", "Cmd+Shift+E - End Activity")
        self.end_activity(None)
    
    def hotkey_end_day(self):
        """Global hotkey handler for end day"""
        rumps.notification("TimeDeck", "Hotkey Pressed", "Cmd+Shift+D - End Day Summary")
        self.end_day(None)
    
    def update_title(self, _=None):
        """Update the menu bar title with current activity info"""
        try:
            if self.log_file.exists():
                with open(self.log_file, 'r') as f:
                    lines = f.readlines()
                    if lines:
                        last_line = lines[-1].strip()
                        if not last_line.endswith("END"):
                            parts = last_line.split(" ", 1)
                            if len(parts) >= 2:
                                timestamp = int(parts[0])
                                activity_name = parts[1]
                                duration = int(time.time()) - timestamp
                                hours = duration // 3600
                                minutes = (duration % 3600) // 60
                                
                                # Update the "Current Activity" menu item
                                if "Current Activity" in self.menu:
                                    self.menu["Current Activity"].title = f"🟢 {activity_name} ({hours}h {minutes}m)"
                                
                                # Update app title to show active status
                                # Keep the icon the same, just update the title
                                return
            
                    # No current activity
        if "Current Activity" in self.menu:
            self.menu["Current Activity"].title = "⚪ No active activity"
            
        except Exception as e:
            print(f"Error updating title: {e}")
    
    def run_applescript(self, script_name, args=None):
        """Run an AppleScript file"""
        script_path = self.script_dir / script_name
        cmd = ["osascript", str(script_path)]
        if args:
            cmd.extend(args)
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                rumps.alert(f"Error running {script_name}", result.stderr)
        except Exception as e:
            rumps.alert("Error", str(e))
    
    @rumps.clicked("Current Activity")
    def current_activity_clicked(self, _):
        """Show current activity info"""
        self.update_title()
    
    @rumps.clicked("New Activity")
    def new_activity(self, _):
        """Start a new activity"""
        response = rumps.Window(
            "Enter activity name:",
            title="New Activity (Cmd+N or Cmd+Shift+N)",
            default_text="",
            ok="Start Activity",
            cancel="Cancel",
            dimensions=(320, 160)
        ).run()
        
        if response.clicked and response.text.strip():
            self.run_applescript("NewActivity.applescript", [response.text.strip()])
            self.update_title()
    
    @rumps.clicked("End Activity")
    def end_activity(self, _):
        """End the current activity"""
        self.run_applescript("EndActivity.applescript")
        self.update_title()
    
    @rumps.clicked("End Day Summary")
    def end_day(self, _):
        """Generate end of day summary"""
        self.run_applescript("EndDay.applescript")
        self.update_title()
    
    @rumps.clicked("Generate Report")
    def generate_report(self, _):
        """Generate detailed report"""
        self.run_applescript("GenerateReport.applescript")
    
    @rumps.clicked("Start Fresh")
    def start_fresh(self, _):
        """Clear all activity data"""
        if rumps.alert("Start Fresh", 
                      "This will clear all activity data. Are you sure?", 
                      ok="Yes, Clear All Data", 
                      cancel="Cancel") == 1:
            self.run_applescript("StartFresh.applescript")
            self.update_title()
    
    @rumps.clicked("Open Log File")
    def open_log_file(self, _):
        """Open the log file"""
        if self.log_file.exists():
            subprocess.run(["open", str(self.log_file)])
        else:
            rumps.alert("Log File Not Found", "No activity log file found on Desktop")
    
    @rumps.clicked("Open Report File")
    def open_report_file(self, _):
        """Open the report file"""
        if self.report_file.exists():
            subprocess.run(["open", str(self.report_file)])
        else:
            rumps.alert("Report File Not Found", "No report file found on Desktop. Generate a report first.")
    
    @rumps.clicked("Keyboard Shortcuts")
    def show_shortcuts(self, _):
        """Show available keyboard shortcuts"""
        if GLOBAL_HOTKEYS_AVAILABLE:
            shortcuts = """Keyboard Shortcuts Available:

Menu Shortcuts (when TimeDeck menu is open):
• Cmd+N - New Activity
• Cmd+E - End Activity  
• Cmd+D - End Day Summary
• Cmd+R - Generate Report

Global Shortcuts (work anywhere):
• Cmd+Shift+N - New Activity
• Cmd+Shift+E - End Activity
• Cmd+Shift+D - End Day Summary

StreamDeck Integration:
Use AppleScript files in:
/Applications/TimeDeck.app/Contents/Scripts/"""
        else:
            shortcuts = """Menu Shortcuts Available:

When TimeDeck menu is open:
• Cmd+N - New Activity
• Cmd+E - End Activity  
• Cmd+D - End Day Summary
• Cmd+R - Generate Report

For global hotkeys, install: pip3 install keyboard

StreamDeck Integration:
Use AppleScript files directly with osascript"""
        
        rumps.alert("TimeDeck Shortcuts", shortcuts)
    
    @rumps.clicked("Menu Shortcuts Only")
    def show_menu_shortcuts(self, _):
        """Show menu shortcuts when global hotkeys aren't available"""
        self.show_shortcuts(_)

def main():
    """Main entry point for the application"""
    app = TimeDeckApp()
    app.run()

if __name__ == "__main__":
    main()
