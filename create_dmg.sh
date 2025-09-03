#!/bin/bash
# Create a professional TimeDeck DMG installer

set -e

echo "📀 Creating TimeDeck DMG installer..."

# Configuration
APP_NAME="TimeDeck"
VERSION="0.0.2"
DMG_NAME="TimeDeck-${VERSION}"
TEMP_DIR="dmg_temp"
DMG_DIR="dmg_build"

# Clean previous builds
rm -rf "$TEMP_DIR" "$DMG_DIR" "TimeDeck-*.dmg"

# Create temporary directories
mkdir -p "$TEMP_DIR" "$DMG_DIR"

echo "🏗️  Building application bundle..."

# Build the app first
./build_app.sh

# Copy the built app to DMG directory
cp -R "build/${APP_NAME}.app" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create a nice README for the DMG
cat > "$DMG_DIR/Installation Guide.txt" << EOF
📊 TimeDeck v${VERSION} - Native Activity Tracking for Mac
=========================================================

🚀 QUICK INSTALL:
   Drag "TimeDeck.app" to the "Applications" folder

📱 TO USE:
   1. Open TimeDeck from Applications or Spotlight
   2. Look for the TimeDeck icon in your menu bar
   3. Click it to access all features

✨ FEATURES:
   • Track activities throughout your day
   • Generate detailed time reports  
   • Native Mac menu bar app
   • Automatic time calculations
   • Export reports for analysis
   • StreamDeck integration

🍎 NATIVE MAC APPLICATION:
   • 100% native Swift implementation
   • No external dependencies required
   • Professional menu bar integration
   • Custom icons and Mac-native UI
   • Optimized performance and memory usage

🔧 REQUIREMENTS:
   • macOS 10.14 or later
   • No additional software needed!

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
echo "🍎 Native Mac App Features:"
echo "   • Pure Swift implementation"
echo "   • Zero external dependencies"
echo "   • Professional menu bar integration"
echo "   • Custom icons and native UI"
echo "   • Optimized performance"
echo ""
echo "🚀 Distribution ready!"
echo "   Users can:"
echo "   1. Download and open the DMG"
echo "   2. Drag TimeDeck.app to Applications"
echo "   3. Launch from Applications or Spotlight"
echo "   4. Enjoy the native menu bar app!"

# Show the file in Finder
if command -v open &> /dev/null; then
    open .
fi
