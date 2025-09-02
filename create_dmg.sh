#!/bin/bash
# Create a professional DMG installer for Hacktivity

set -e

echo "📀 Creating Hacktivity DMG installer..."

# Configuration
APP_NAME="Hacktivity"
VERSION="1.0.0"
DMG_NAME="Hacktivity-${VERSION}"
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
</dict>
</plist>
EOF

# Create the main executable script
cat > "$APP_BUNDLE/Contents/MacOS/Hacktivity" << 'EOF'
#!/bin/bash
# Hacktivity launcher script

# Get the directory where this app bundle is located
BUNDLE_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
SCRIPT_DIR="$BUNDLE_DIR/Contents/Scripts"

cd "$SCRIPT_DIR"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    osascript -e 'display dialog "Python 3 is required but not found. Please install Python 3 and try again." with title "Hacktivity Error" buttons {"OK"} default button "OK"'
    exit 1
fi

# Check if rumps is installed
if ! python3 -c "import rumps" 2>/dev/null; then
    osascript -e 'display dialog "Installing dependencies... This may take a moment." with title "Hacktivity Setup" buttons {"OK"} default button "OK"'
    python3 -m pip install --user rumps
fi

# Launch the menu bar app
exec python3 hacktivity_menubar.py
EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/Hacktivity"

# Copy all necessary files to the Scripts directory
cp hacktivity_menubar.py "$APP_BUNDLE/Contents/Scripts/"
cp *.applescript "$APP_BUNDLE/Contents/Scripts/"
cp requirements.txt "$APP_BUNDLE/Contents/Scripts/"

# Create application icon placeholder
# You can replace this with a proper .icns file later
mkdir -p "$APP_BUNDLE/Contents/Resources"
echo "# Icon placeholder - replace with proper .icns file" > "$APP_BUNDLE/Contents/Resources/icon_placeholder.txt"

echo "📦 Creating DMG contents..."

# Copy app bundle to DMG directory
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create a nice Applications symlink for drag-and-drop installation
ln -s /Applications "$DMG_DIR/Applications"

# Create a README for the DMG
cat > "$DMG_DIR/README.txt" << EOF
Hacktivity v${VERSION}
===================

Installation:
1. Drag Hacktivity.app to the Applications folder
2. Launch Hacktivity from Applications or Spotlight
3. Look for the 📊 icon in your menu bar

Features:
• Track activities throughout your day
• Generate time reports
• Menu bar access to all functions
• Automatic time calculations

For support or updates, visit:
https://github.com/joomux/timedeck

Enjoy productive time tracking!
EOF

# Create DS_Store file for nice DMG layout (optional)
# This would require more complex scripting, but improves the user experience

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

echo "✅ DMG created successfully!"
echo ""
echo "📀 File: ${DMG_NAME}.dmg"
echo "📏 Size: $(du -h "${DMG_NAME}.dmg" | cut -f1)"
echo ""
echo "🚀 Distribution ready!"
echo "   Users can:"
echo "   1. Download and open the DMG"
echo "   2. Drag Hacktivity.app to Applications"
echo "   3. Launch from Applications or Spotlight"
echo "   4. Enjoy the menu bar app!"

# Show the file in Finder
if command -v open &> /dev/null; then
    open .
fi
