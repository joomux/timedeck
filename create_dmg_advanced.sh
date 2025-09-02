#!/bin/bash
# Create a professional DMG installer with custom layout for Hacktivity

set -e

echo "🎨 Creating advanced Hacktivity DMG installer..."

# Configuration
APP_NAME="Hacktivity"
VERSION="1.0.0"
DMG_NAME="Hacktivity-${VERSION}"
TEMP_DIR="dmg_temp"
DMG_DIR="dmg_build"
BACKGROUND_FILE="dmg_background.png"

# Clean previous builds
rm -rf "$TEMP_DIR" "$DMG_DIR" *.dmg

# Create temporary directories
mkdir -p "$TEMP_DIR" "$DMG_DIR"

echo "🏗️  Building application bundle..."

# Create the app bundle (same as before)
APP_BUNDLE="$TEMP_DIR/${APP_NAME}.app"
mkdir -p "$APP_BUNDLE/Contents/"{MacOS,Resources,Scripts}

# Create Info.plist with more details
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Hacktivity</string>
    <key>CFBundleIdentifier</key>
    <string>com.hacktivity.menubar</string>
    <key>CFBundleName</key>
    <string>Hacktivity</string>
    <key>CFBundleDisplayName</key>
    <string>Hacktivity</string>
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
    <string>Hacktivity ${VERSION} - Activity tracking for Mac</string>
</dict>
</plist>
EOF

# Create the main executable script (improved with better error handling)
cat > "$APP_BUNDLE/Contents/MacOS/Hacktivity" << 'EOF'
#!/bin/bash
# Hacktivity launcher script with improved error handling

# Get the directory where this app bundle is located
BUNDLE_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
SCRIPT_DIR="$BUNDLE_DIR/Contents/Scripts"

cd "$SCRIPT_DIR"

# Function to show error dialog
show_error() {
    osascript -e "display dialog \"$1\" with title \"Hacktivity Error\" buttons {\"OK\"} default button \"OK\" with icon stop"
}

# Function to show info dialog
show_info() {
    osascript -e "display dialog \"$1\" with title \"Hacktivity\" buttons {\"OK\"} default button \"OK\""
}

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    show_error "Python 3 is required but not found.\n\nPlease install Python 3 from python.org and try again."
    exit 1
fi

# Check Python version (require 3.8+)
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
REQUIRED_VERSION="3.8"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
    show_error "Python ${REQUIRED_VERSION} or higher is required.\nFound: Python ${PYTHON_VERSION}\n\nPlease update Python and try again."
    exit 1
fi

# Check if rumps is installed
if ! python3 -c "import rumps" 2>/dev/null; then
    show_info "Setting up Hacktivity dependencies...\n\nThis will install the required Python packages and may take a moment."
    
    if ! python3 -m pip install --user rumps; then
        show_error "Failed to install dependencies.\n\nPlease check your internet connection and try again."
        exit 1
    fi
    
    show_info "Setup complete! Hacktivity is ready to use.\n\nLook for the 📊 icon in your menu bar."
fi

# Launch the menu bar app
exec python3 hacktivity_menubar.py
EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/Hacktivity"

# Copy all necessary files
cp hacktivity_menubar.py "$APP_BUNDLE/Contents/Scripts/"
cp *.applescript "$APP_BUNDLE/Contents/Scripts/"
cp requirements.txt "$APP_BUNDLE/Contents/Scripts/"

echo "🎨 Creating DMG with custom layout..."

# Copy app bundle to DMG directory
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create an attractive README
cat > "$DMG_DIR/Installation Guide.txt" << EOF
📊 Hacktivity v${VERSION} - Activity Tracking for Mac
======================================================

🚀 QUICK INSTALL:
   Drag "Hacktivity.app" to the "Applications" folder

📱 TO USE:
   1. Open Hacktivity from Applications or Spotlight
   2. Look for the 📊 icon in your menu bar
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
   Add Hacktivity to "Login Items" in System Preferences
   to start automatically when you log in.

📞 SUPPORT:
   Visit: https://github.com/joomux/timedeck
   
Happy time tracking! 🎯
EOF

# Create a simple background image using ImageMagick if available
if command -v convert &> /dev/null; then
    echo "🖼️  Creating background image..."
    convert -size 600x400 xc:white \
        -font "Arial" -pointsize 24 -fill "#333333" \
        -gravity center -annotate +0-100 "Hacktivity" \
        -pointsize 14 -annotate +0-60 "Activity Tracking for Mac" \
        -pointsize 12 -fill "#666666" \
        -annotate +0+150 "Drag Hacktivity.app to Applications" \
        "$DMG_DIR/.background.png"
else
    echo "ℹ️  ImageMagick not found, skipping custom background"
fi

echo "💿 Building DMG with custom settings..."

# Create initial DMG
hdiutil create -volname "$DMG_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDRW \
    "${DMG_NAME}_temp.dmg"

# Mount the DMG to customize it
MOUNT_DIR="/Volumes/$DMG_NAME"
hdiutil attach "${DMG_NAME}_temp.dmg"

# Wait for mount
sleep 2

# Customize the DMG window (if mounted successfully)
if [ -d "$MOUNT_DIR" ]; then
    echo "🎨 Customizing DMG layout..."
    
    # Create .DS_Store for custom layout
    osascript << EOF
tell application "Finder"
    tell disk "$DMG_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set background picture of viewOptions to file ".background.png"
        set position of item "Hacktivity.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        set position of item "Installation Guide.txt" of container window to {300, 350}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

    # Hide background file
    if [ -f "$MOUNT_DIR/.background.png" ]; then
        SetFile -a V "$MOUNT_DIR/.background.png"
    fi
    
    # Eject the DMG
    hdiutil detach "$MOUNT_DIR"
else
    echo "⚠️  Could not mount DMG for customization"
fi

# Convert to final compressed DMG
hdiutil convert "${DMG_NAME}_temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_NAME.dmg"

# Clean up
rm -rf "$TEMP_DIR" "$DMG_DIR" "${DMG_NAME}_temp.dmg"

echo "✅ Professional DMG created successfully!"
echo ""
echo "📀 File: ${DMG_NAME}.dmg"
echo "📏 Size: $(du -h "${DMG_NAME}.dmg" | cut -f1)"
echo ""
echo "🎯 Professional Mac distribution ready!"
echo "   Features:"
echo "   • Custom DMG layout with drag-to-install"
echo "   • Proper Mac app bundle"
echo "   • Automatic dependency installation"
echo "   • Professional installer experience"
echo "   • Ready for Mac App Store style distribution"

# Open Finder to show the result
if command -v open &> /dev/null; then
    open .
fi
