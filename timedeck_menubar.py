#!/usr/bin/env python3
"""
TimeDeck Menu Bar App
A menu bar application for quick access to TimeDeck scripts
"""

import rumps
import subprocess
import os
import time
from pathlib import Path

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
        
        # Set up menu items
        self.menu = [
            "Current Activity",
            None,  # Separator
            "New Activity",
            "End Activity", 
            None,  # Separator
            "End Day Summary",
            "Generate Report",
            None,  # Separator
            "Start Fresh",
            None,  # Separator
            "Open Log File",
            "Open Report File"
        ]
        
        # Update title with current activity info
        self.update_title()
        
        # Set up timer to update every 30 seconds
        self.timer = rumps.Timer(self.update_title, 30)
        self.timer.start()
    
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
            title="New Activity",
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

def main():
    """Main entry point for the application"""
    app = TimeDeckApp()
    app.run()

if __name__ == "__main__":
    main()
