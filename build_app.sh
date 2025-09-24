#!/bin/bash
# Build native TimeDeck app

set -e

echo "🍎 Building native TimeDeck app..."

APP_NAME="TimeDeck"
BUILD_DIR="build"
SWIFT_FILES="main.swift TimeDeckApp.swift ActivityTemplate.swift TemplateManager.swift ActivityTracker.swift NotificationManager.swift Analytics.swift HTTPServer.swift DataManager.swift AlertManager.swift Extensions.swift"

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Compile Swift app with all modules
echo "⚙️  Compiling Swift code..."
if [ -f "TimeDeck.entitlements" ]; then
    echo "📋 Using entitlements file..."
    swiftc -o "$BUILD_DIR/$APP_NAME" $SWIFT_FILES
else
    swiftc -o "$BUILD_DIR/$APP_NAME" $SWIFT_FILES
fi

# Create app bundle
echo "📦 Creating app bundle..."
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
mkdir -p "$APP_BUNDLE/Contents/"{MacOS,Resources,Scripts}

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TimeDeck</string>
    <key>CFBundleIdentifier</key>
    <string>com.timedeck.native</string>
    <key>CFBundleName</key>
    <string>TimeDeck</string>
    <key>CFBundleDisplayName</key>
    <string>TimeDeck</string>
    <key>CFBundleVersion</key>
    <string>0.0.3</string>
    <key>CFBundleShortVersionString</key>
    <string>0.0.3</string>
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
    <string>TimeDeck 0.0.3 - Native Activity Tracking for Mac</string>
    <key>CFBundleIconFile</key>
    <string>TimeDeck.icns</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>TimeDeck URL Scheme</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>timedeck</string>
            </array>
            <key>CFBundleURLIconFile</key>
            <string>TimeDeck.icns</string>
        </dict>
    </array>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
    <key>NSUserNotificationCenterEnableApplicationActivation</key>
    <true/>
    <key>NSUserNotificationCenterActivationPolicy</key>
    <string>accessory</string>
</dict>
</plist>
EOF

# Copy icons if available
if [ -f "icons/TimeDeck.icns" ]; then
    cp "icons/TimeDeck.icns" "$APP_BUNDLE/Contents/Resources/"
    echo "✅ Added TimeDeck app icon"
fi

# Copy menu bar icons
if [ -f "icons/menubar_icon.png" ]; then
    cp "icons/menubar_icon.png" "$APP_BUNDLE/Contents/Resources/"
    echo "✅ Added menu bar icon"
fi

if [ -f "icons/menubar_icon@2x.png" ]; then
    cp "icons/menubar_icon@2x.png" "$APP_BUNDLE/Contents/Resources/"
    echo "✅ Added menu bar icon @2x"
fi

# Copy AppleScript files
cp *.applescript "$APP_BUNDLE/Contents/Scripts/"

# Copy StreamDeck shell scripts to Resources
if [ -d "$APP_BUNDLE/Contents/Resources/StreamDeck" ]; then
    rm -rf "$APP_BUNDLE/Contents/Resources/StreamDeck"
fi
mkdir -p "$APP_BUNDLE/Contents/Resources/StreamDeck"

# Copy streamlined timedeck shell scripts
cp timedeck_*.sh "$APP_BUNDLE/Contents/Resources/StreamDeck/" 2>/dev/null || true

echo "✅ Added StreamDeck integration scripts"

echo "✅ Native TimeDeck app created!"
echo "📁 Location: $APP_BUNDLE"
echo ""
echo "🚀 To install:"
echo "   cp -R \"$APP_BUNDLE\" /Applications/"
echo ""
echo "🎯 Features:"
echo "   • Native Mac menu bar app"
echo "   • No external dependencies"
echo "   • Custom menu bar icon"
echo "   • Activity tracking with live timer"
echo "   • StreamDeck integration"
