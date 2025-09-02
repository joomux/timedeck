#!/bin/bash
# Create a professional TimeDeck DMG installer

set -e

echo "📀 Creating TimeDeck DMG installer..."

# Configuration
APP_NAME="TimeDeck"
VERSION="1.0.0"
DMG_NAME="TimeDeck-${VERSION}"
TEMP_DIR="dmg_temp"
DMG_DIR="dmg_build"

# Clean previous builds
rm -rf "$TEMP_DIR" "$DMG_DIR" *.dmg

# Create temporary directories
mkdir -p "$TEMP_DIR" "$DMG_DIR"

echo "🏗️  Building application bundle..."

# Create the app bundle structure
APP_BUNDLE="$TEMP_DIR/${APP_NAME}.app"
mkdir -p "$APP_BUNDLE/Contents/"{MacOS,Resources,Scripts}

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TimeDeck</string>
    <key>CFBundleIdentifier</key>
    <string>com.timedeck.menubar</string>
    <key>CFBundleName</key>
    <string>TimeDeck</string>
    <key>CFBundleDisplayName</key>
    <string>TimeDeck</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.14</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Jeremy Roberts. All rights reserved.</string>
    <key>CFBundleGetInfoString</key>
    <string>TimeDeck ${VERSION} - Activity tracking for Mac</string>
    <key>CFBundleIconFile</key>
    <string>TimeDeck.icns</string>
</dict>
</plist>
EOF

# Create the main executable script with improved error handling
cat > "$APP_BUNDLE/Contents/MacOS/TimeDeck" << 'EOF'
#!/bin/bash
# TimeDeck launcher script

# Get the directory where this app bundle is located
BUNDLE_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
SCRIPT_DIR="$BUNDLE_DIR/Contents/Scripts"

cd "$SCRIPT_DIR"

# Function to show error dialog
show_error() {
    osascript -e "display dialog \"$1\" with title \"TimeDeck Error\" buttons {\"OK\"} default button \"OK\" with icon stop"
}

# Function to show info dialog
show_info() {
    osascript -e "display dialog \"$1\" with title \"TimeDeck\" buttons {\"OK\"} default button \"OK\""
}

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    show_error "Python 3 is required but not found.\n\nPlease install Python 3 from python.org and try again."
    exit 1
fi

# Check Python version (require 3.8+)
if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    show_error "Python 3.8 or higher is required.\nFound: Python ${PYTHON_VERSION}\n\nPlease update Python and try again."
    exit 1
fi

# Check if rumps is installed
if ! python3 -c "import rumps" 2>/dev/null; then
    show_info "Setting up TimeDeck dependencies...\n\nThis will install the required Python packages and may take a moment."
    
    if ! python3 -m pip install --user rumps; then
        show_error "Failed to install dependencies.\n\nPlease check your internet connection and try again."
        exit 1
    fi
    
    show_info "Setup complete! TimeDeck is ready to use.\n\nLook for the TimeDeck icon in your menu bar."
fi

# Launch the menu bar app
exec python3 timedeck_menubar.py
EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/TimeDeck"

# Copy the proper icon
if [ -f "icons/TimeDeck.icns" ]; then
    cp "icons/TimeDeck.icns" "$APP_BUNDLE/Contents/Resources/"
    echo "✅ Added TimeDeck icon"
else
    echo "⚠️  TimeDeck.icns not found, using default"
fi

# Copy all necessary files to the Scripts directory
cp timedeck_menubar.py "$APP_BUNDLE/Contents/Scripts/"
cp *.applescript "$APP_BUNDLE/Contents/Scripts/"
cp requirements.txt "$APP_BUNDLE/Contents/Scripts/"

echo "📦 Creating DMG contents..."

# Copy app bundle to DMG directory
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create a nice README for the DMG
cat > "$DMG_DIR/Installation Guide.txt" << EOF
📊 TimeDeck v${VERSION} - Activity Tracking for Mac
==================================================

🚀 QUICK INSTALL:
   Drag "TimeDeck.app" to the "Applications" folder

📱 TO USE:
   1. Open TimeDeck from Applications or Spotlight
   2. Look for the TimeDeck icon in your menu bar
   3. Click it to access all features

✨ FEATURES:
   • Track activities throughout your day
   • Generate detailed time reports  
   • Menu bar convenience
   • Automatic time calculations
   • Export reports for analysis

🔧 REQUIREMENTS:
   • macOS 10.14 or later
   • Python 3.8+ (will install dependencies automatically)

💡 TIP:
   Add TimeDeck to "Login Items" in System Preferences
   to start automatically when you log in.

📞 SUPPORT:
   Visit: https://github.com/joomux/timedeck
   
Happy time tracking! 🎯
EOF

# Add custom DMG background if available
if [ -f "icons/dmg_background.png" ]; then
    cp "icons/dmg_background.png" "$DMG_DIR/.background.png"
fi

echo "💿 Building DMG file..."

# Create the DMG
hdiutil create -volname "$DMG_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_NAME.dmg"

# Clean up temporary files
rm -rf "$TEMP_DIR" "$DMG_DIR"

echo "✅ TimeDeck DMG created successfully!"
echo ""
echo "📀 File: ${DMG_NAME}.dmg"
echo "📏 Size: $(du -h "${DMG_NAME}.dmg" | cut -f1)"
echo ""
echo "🚀 Distribution ready!"
echo "   Users can:"
echo "   1. Download and open the DMG"
echo "   2. Drag TimeDeck.app to Applications"
echo "   3. Launch from Applications or Spotlight"
echo "   4. Enjoy the menu bar app!"

# Show the file in Finder
if command -v open &> /dev/null; then
    open .
fi
