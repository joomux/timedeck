#!/usr/bin/env python3
"""
TimeDeck Menu Bar App with Configurable Keyboard Shortcuts
A menu bar application for quick access to TimeDeck scripts with user-configurable global hotkeys
"""

import rumps
import subprocess
import os
import time
import threading
import json
from pathlib import Path

# Try to import keyboard for global hotkeys (optional)
try:
    import keyboard
    GLOBAL_HOTKEYS_AVAILABLE = True
except ImportError:
    GLOBAL_HOTKEYS_AVAILABLE = False

class TimeDeckApp(rumps.App):
    def __init__(self):
        # Use emoji icon to avoid path issues
        super(TimeDeckApp, self).__init__("📊", title="TimeDeck")
        
        # Set up paths
        self.script_dir = Path(__file__).parent
        self.log_file = Path.home() / "Desktop" / "timedeck_log.txt"
        self.report_file = Path.home() / "Desktop" / "timedeck_report.txt"
        self.preferences_file = Path.home() / "Library" / "Preferences" / "com.timedeck.preferences.json"
        
        # Load preferences
        self.preferences = self.load_preferences()
        
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
            "Preferences" if GLOBAL_HOTKEYS_AVAILABLE else "Menu Shortcuts Only",
            "Keyboard Shortcuts"
        ]
        
        # Track registered hotkeys for cleanup
        self.registered_hotkeys = []
        
        # Update title with current activity info
        self.update_title()
        
        # Set up timer to update every 30 seconds
        self.timer = rumps.Timer(self.update_title, 30)
        self.timer.start()
        
        # Set up global hotkeys if available
        if GLOBAL_HOTKEYS_AVAILABLE:
            self.setup_global_hotkeys()
    
    def load_preferences(self):
        """Load user preferences from file"""
        default_preferences = {
            "global_shortcuts": {
                "new_activity": "cmd+shift+n",
                "end_activity": "cmd+shift+e", 
                "end_day": "cmd+shift+d"
            },
            "notifications_enabled": True
        }
        
        try:
            if self.preferences_file.exists():
                with open(self.preferences_file, 'r') as f:
                    saved_prefs = json.load(f)
                    # Merge with defaults to ensure all keys exist
                    for key, value in default_preferences.items():
                        if key not in saved_prefs:
                            saved_prefs[key] = value
                    return saved_prefs
        except Exception as e:
            print(f"Error loading preferences: {e}")
        
        return default_preferences
    
    def save_preferences(self):
        """Save user preferences to file"""
        try:
            # Ensure directory exists
            self.preferences_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.preferences_file, 'w') as f:
                json.dump(self.preferences, f, indent=2)
        except Exception as e:
            print(f"Error saving preferences: {e}")
    
    def clear_global_hotkeys(self):
        """Clear all registered global hotkeys"""
        if GLOBAL_HOTKEYS_AVAILABLE:
            for hotkey in self.registered_hotkeys:
                try:
                    keyboard.remove_hotkey(hotkey)
                except:
                    pass
            self.registered_hotkeys.clear()
    
    def setup_global_hotkeys(self):
        """Set up global keyboard shortcuts from preferences"""
        if not GLOBAL_HOTKEYS_AVAILABLE:
            return
            
        # Clear existing hotkeys first
        self.clear_global_hotkeys()
        
        shortcuts = self.preferences.get("global_shortcuts", {})
        
        try:
            # Register hotkeys from preferences
            if shortcuts.get("new_activity"):
                hotkey = keyboard.add_hotkey(shortcuts["new_activity"], self.hotkey_new_activity)
                self.registered_hotkeys.append(hotkey)
                
            if shortcuts.get("end_activity"):
                hotkey = keyboard.add_hotkey(shortcuts["end_activity"], self.hotkey_end_activity)
                self.registered_hotkeys.append(hotkey)
                
            if shortcuts.get("end_day"):
                hotkey = keyboard.add_hotkey(shortcuts["end_day"], self.hotkey_end_day)
                self.registered_hotkeys.append(hotkey)
                
            print("Global hotkeys enabled:")
            print(f"  {shortcuts.get('new_activity', 'None')} - New Activity")
            print(f"  {shortcuts.get('end_activity', 'None')} - End Activity") 
            print(f"  {shortcuts.get('end_day', 'None')} - End Day Summary")
        except Exception as e:
            print(f"Could not set up global hotkeys: {e}")
    
    def hotkey_new_activity(self):
        """Global hotkey handler for new activity"""
        if self.preferences.get("notifications_enabled", True):
            shortcut = self.preferences["global_shortcuts"].get("new_activity", "")
            rumps.notification("TimeDeck", "Hotkey Pressed", f"{shortcut} - New Activity")
        self.new_activity(None)
    
    def hotkey_end_activity(self):
        """Global hotkey handler for end activity"""
        if self.preferences.get("notifications_enabled", True):
            shortcut = self.preferences["global_shortcuts"].get("end_activity", "")
            rumps.notification("TimeDeck", "Hotkey Pressed", f"{shortcut} - End Activity")
        self.end_activity(None)
    
    def hotkey_end_day(self):
        """Global hotkey handler for end day"""
        if self.preferences.get("notifications_enabled", True):
            shortcut = self.preferences["global_shortcuts"].get("end_day", "")
            rumps.notification("TimeDeck", "Hotkey Pressed", f"{shortcut} - End Day Summary")
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
            title="New Activity (Cmd+N)",
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
    
    @rumps.clicked("Preferences")
    def show_preferences(self, _):
        """Show preferences window"""
        if not GLOBAL_HOTKEYS_AVAILABLE:
            rumps.alert("Global Hotkeys Not Available", 
                       "To configure global shortcuts, install the keyboard library:\npip3 install keyboard")
            return
            
        self.open_preferences_window()
    
    def open_preferences_window(self):
        """Open a comprehensive preferences window"""
        self.configure_shortcuts_properly()
    
    def configure_shortcuts_properly(self):
        """Configure shortcuts with individual fields and keyboard capture"""
        shortcuts = [
            ("new_activity", "New Activity", "Start a new activity"),
            ("end_activity", "End Activity", "End current activity"),
            ("end_day", "End Day Summary", "Generate daily summary")
        ]
        
        new_shortcuts = {}
        current_shortcuts = self.preferences["global_shortcuts"]
        
        # Configure each shortcut individually with better UI
        for key, name, description in shortcuts:
            current = current_shortcuts.get(key, f"cmd+shift+{key[0]}")
            new_shortcut = self.capture_keyboard_shortcut(name, description, current)
            if new_shortcut:
                new_shortcuts[key] = new_shortcut
            else:
                # User cancelled or no change, keep current
                new_shortcuts[key] = current
        
        # Configure notifications
        notifications_response = rumps.alert(
            "Notifications", 
            "Show notifications when hotkeys are pressed?",
            ok="Enable Notifications", 
            cancel="Disable Notifications"
        )
        
        notifications_enabled = notifications_response == 1
        
        # Save all changes
        for key, value in new_shortcuts.items():
            self.preferences["global_shortcuts"][key] = value
        self.preferences["notifications_enabled"] = notifications_enabled
        
        self.save_preferences()
        self.setup_global_hotkeys()
        
        # Show summary
        summary = "Shortcuts Updated Successfully!\n\n"
        for key, value in new_shortcuts.items():
            action_name = key.replace('_', ' ').title()
            summary += f"{action_name}: {value}\n"
        summary += f"\nNotifications: {'Enabled' if notifications_enabled else 'Disabled'}"
        
        rumps.alert("Preferences Saved", summary)
    
    def capture_keyboard_shortcut(self, action_name, description, current_shortcut):
        """Capture a keyboard shortcut with a better UI"""
        # Show current shortcut and options to change it
        message = f"""Configure shortcut for: {action_name}
        
{description}

Current shortcut: {current_shortcut}

Choose an option:"""
        
        response = rumps.alert(
            f"Configure {action_name}",
            message,
            ok="Change Shortcut",
            cancel="Keep Current"
        )
        
        if response != 1:  # Keep current
            return None
            
        # Show keyboard capture dialog
        return self.show_shortcut_input_dialog(action_name, current_shortcut)
    
    def show_shortcut_input_dialog(self, action_name, current_shortcut):
        """Show dialog with real keyboard capture"""
        if not GLOBAL_HOTKEYS_AVAILABLE:
            # Fallback to text input if keyboard library not available
            return self.show_text_shortcut_input(action_name, current_shortcut)
        
        # First, ask user if they want to capture keys or type manually
        choice = rumps.alert(
            f"Configure {action_name}",
            f"""Current shortcut: {current_shortcut}

How would you like to set the new shortcut?""",
            ok="Capture Keys (Press Keys)",
            cancel="Type Manually"
        )
        
        if choice == 1:
            # Use keyboard capture
            return self.capture_keys_real_time(action_name, current_shortcut)
        else:
            # Use text input
            return self.show_text_shortcut_input(action_name, current_shortcut)
    
    def capture_keys_real_time(self, action_name, current_shortcut):
        """Capture keyboard shortcut in real-time"""
        try:
            # Show instructions and wait for key press
            rumps.alert(
                f"Capture Keys for {action_name}",
                """Ready to capture your shortcut!

1. Click OK to start capturing
2. Press your desired key combination
3. The shortcut will be captured automatically

Press Escape to cancel.""",
                ok="Start Capturing",
                cancel="Cancel"
            )
            
            captured_shortcut = self.listen_for_shortcut()
            
            if captured_shortcut:
                # Confirm the captured shortcut
                confirm = rumps.alert(
                    "Confirm Shortcut",
                    f"""Captured shortcut: {captured_shortcut}

Use this shortcut for {action_name}?""",
                    ok="Use This Shortcut",
                    cancel="Try Again"
                )
                
                if confirm == 1:
                    return captured_shortcut
                else:
                    return self.capture_keys_real_time(action_name, current_shortcut)
            else:
                # Capture was cancelled
                return None
                
        except Exception as e:
            rumps.alert("Capture Error", f"Could not capture keys: {e}")
            return self.show_text_shortcut_input(action_name, current_shortcut)
    
    def listen_for_shortcut(self):
        """Listen for a keyboard shortcut and return it"""
        if not GLOBAL_HOTKEYS_AVAILABLE:
            return None
            
        modifiers = set()
        main_key = None
        cancelled = False
        
        def on_key_event(event):
            nonlocal modifiers, main_key, cancelled
            
            if event.event_type == keyboard.KEY_DOWN:
                key_name = event.name.lower()
                
                # Handle modifiers
                if key_name in ['ctrl', 'alt', 'shift', 'cmd', 'left ctrl', 'right ctrl', 'left alt', 'right alt', 'left shift', 'right shift']:
                    if 'ctrl' in key_name:
                        modifiers.add('ctrl')
                    elif 'alt' in key_name:
                        modifiers.add('alt')
                    elif 'shift' in key_name:
                        modifiers.add('shift')
                    elif key_name == 'cmd':
                        modifiers.add('cmd')
                
                # Handle escape to cancel
                elif key_name == 'esc':
                    cancelled = True
                    return False
                
                # Handle regular keys (letters and numbers)
                elif len(key_name) == 1 and key_name.isalnum():
                    main_key = key_name
                    return False
                    
                # Handle some special keys that might be useful
                elif key_name in ['space', 'tab', 'enter']:
                    main_key = key_name
                    return False
            
            return True
        
        try:
            # Register the event handler
            keyboard.hook(on_key_event)
            
            # Wait for key capture with timeout
            import time
            start_time = time.time()
            timeout = 15  # 15 second timeout
            
            while main_key is None and not cancelled and (time.time() - start_time) < timeout:
                time.sleep(0.1)
            
            # Clean up
            keyboard.unhook_all()
            
            if cancelled:
                return None
            elif main_key and modifiers:
                # Format the shortcut
                modifier_list = sorted(list(modifiers))
                shortcut = "+".join(modifier_list + [main_key])
                return shortcut
            elif main_key and not modifiers:
                # Warn about shortcuts without modifiers
                return main_key  # Return just the key, let validation handle it
            else:
                return None
                
        except Exception as e:
            print(f"Error in keyboard listening: {e}")
            try:
                keyboard.unhook_all()
            except:
                pass
            return None
    
    def show_text_shortcut_input(self, action_name, current_shortcut):
        """Fallback text input for shortcuts"""
        instructions = f"""Enter new shortcut for {action_name}:

Examples:
• cmd+shift+n  (Cmd + Shift + N)
• ctrl+alt+e   (Ctrl + Alt + E)  
• cmd+option+t (Cmd + Option + T)

Valid modifiers: cmd, ctrl, alt, option, shift
Valid keys: a-z, 0-9"""
        
        response = rumps.Window(
            instructions,
            title=f"{action_name} Shortcut",
            default_text=current_shortcut,
            ok="Save",
            cancel="Cancel",
            dimensions=(320, 140)
        ).run()
        
        if response.clicked and response.text.strip():
            new_shortcut = response.text.strip().lower()
            if self.validate_shortcut(new_shortcut):
                return new_shortcut
            else:
                # Show error and try again
                error_response = rumps.alert(
                    "Invalid Shortcut",
                    f"'{new_shortcut}' is not valid.\n\nUse format like: cmd+shift+n\n\nTry again?",
                    ok="Try Again",
                    cancel="Cancel"
                )
                if error_response == 1:
                    return self.show_text_shortcut_input(action_name, current_shortcut)
                
        return None  # Cancelled or invalid
    
    def parse_and_save_preferences(self, prefs_text):
        """Parse the preferences text and save settings"""
        new_shortcuts = {}
        new_notifications = True
        errors = []
        
        for line in prefs_text.split('\n'):
            line = line.strip()
            if not line or '=' not in line:
                continue
                
            try:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip().lower()
                
                if key == 'notifications':
                    new_notifications = value in ['true', '1', 'yes', 'on', 'enabled']
                elif key in ['new_activity', 'end_activity', 'end_day']:
                    if self.validate_shortcut(value):
                        new_shortcuts[key] = value
                    else:
                        errors.append(f"Invalid shortcut for {key}: {value}")
                else:
                    errors.append(f"Unknown setting: {key}")
                    
            except ValueError:
                errors.append(f"Invalid format: {line}")
        
        # Show errors if any
        if errors:
            error_msg = "Some settings were invalid:\n\n" + "\n".join(errors[:5])
            if len(errors) > 5:
                error_msg += f"\n\n...and {len(errors) - 5} more errors"
            rumps.alert("Configuration Errors", error_msg)
            return
        
        # Apply valid settings
        for key, value in new_shortcuts.items():
            self.preferences["global_shortcuts"][key] = value
        
        self.preferences["notifications_enabled"] = new_notifications
        
        # Save and apply changes
        self.save_preferences()
        self.setup_global_hotkeys()
        
        # Show success message with current settings
        success_msg = "Settings saved successfully!\n\nCurrent shortcuts:\n"
        for key, value in self.preferences["global_shortcuts"].items():
            action_name = key.replace('_', ' ').title()
            success_msg += f"• {action_name}: {value}\n"
        
        success_msg += f"\nNotifications: {'Enabled' if self.preferences['notifications_enabled'] else 'Disabled'}"
        
        rumps.alert("Preferences Updated", success_msg)
    
    def validate_shortcut(self, shortcut):
        """Validate shortcut format"""
        if not shortcut:
            return False
            
        # Handle single keys (warn user)
        if '+' not in shortcut:
            if len(shortcut) == 1 and shortcut.isalnum():
                rumps.alert("Single Key Warning", 
                           f"'{shortcut}' is just a single key without modifiers.\n\nThis might conflict with normal typing. Consider adding modifiers like cmd+{shortcut}")
                return True  # Allow it but warn
            return False
            
        # Basic validation - should contain + and valid modifiers
        parts = shortcut.split('+')
        if len(parts) < 2:
            return False
            
        valid_modifiers = {'cmd', 'ctrl', 'alt', 'option', 'shift'}
        valid_keys = set('abcdefghijklmnopqrstuvwxyz0123456789')
        valid_keys.update(['space', 'tab', 'enter'])  # Add special keys
        
        # Check that we have at least one modifier and one key
        has_modifier = any(part in valid_modifiers for part in parts[:-1])
        has_key = parts[-1] in valid_keys
        
        return has_modifier and has_key
    
    @rumps.clicked("Keyboard Shortcuts")
    def show_shortcuts(self, _):
        """Show available keyboard shortcuts"""
        if GLOBAL_HOTKEYS_AVAILABLE:
            shortcuts = self.preferences["global_shortcuts"]
            shortcut_text = f"""Keyboard Shortcuts:

Menu Shortcuts (when TimeDeck menu is open):
• Cmd+N - New Activity
• Cmd+E - End Activity  
• Cmd+D - End Day Summary
• Cmd+R - Generate Report

Global Shortcuts (work anywhere):
• {shortcuts.get('new_activity', 'None')} - New Activity
• {shortcuts.get('end_activity', 'None')} - End Activity
• {shortcuts.get('end_day', 'None')} - End Day Summary

StreamDeck Integration:
Use AppleScript files in:
/Applications/TimeDeck.app/Contents/Scripts/

Click "Preferences" to customize global shortcuts."""
        else:
            shortcut_text = """Menu Shortcuts Available:

When TimeDeck menu is open:
• Cmd+N - New Activity
• Cmd+E - End Activity  
• Cmd+D - End Day Summary
• Cmd+R - Generate Report

For global hotkeys, install: pip3 install keyboard

StreamDeck Integration:
Use AppleScript files directly with osascript"""
        
        rumps.alert("TimeDeck Shortcuts", shortcut_text)
    
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