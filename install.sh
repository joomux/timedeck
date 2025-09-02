#!/bin/bash
# Hacktivity Installation Script
# This script installs Hacktivity and its menu bar app

set -e  # Exit on any error

echo "🚀 Installing Hacktivity..."

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "Please install Python 3 and try again."
    exit 1
fi

# Get installation directory
INSTALL_DIR="$HOME/Applications/Hacktivity"
echo "📁 Installing to: $INSTALL_DIR"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy files
echo "📋 Copying files..."
cp *.applescript "$INSTALL_DIR/"
cp hacktivity_menubar.py "$INSTALL_DIR/"
cp requirements.txt "$INSTALL_DIR/"
cp launch_menubar.sh "$INSTALL_DIR/"

# Make scripts executable
chmod +x "$INSTALL_DIR"/*.sh
chmod +x "$INSTALL_DIR"/*.py

# Install Python dependencies
echo "📦 Installing Python dependencies..."
cd "$INSTALL_DIR"
python3 -m pip install --user -r requirements.txt

# Create launcher script in PATH
LAUNCHER="/usr/local/bin/hacktivity"
echo "🔗 Creating launcher script..."
sudo tee "$LAUNCHER" > /dev/null << EOF
#!/bin/bash
cd "$INSTALL_DIR"
python3 hacktivity_menubar.py
EOF
sudo chmod +x "$LAUNCHER"

# Create desktop application entry (optional)
APP_DIR="$HOME/Applications/Hacktivity.app"
if [[ ! -d "$APP_DIR" ]]; then
    echo "📱 Creating application bundle..."
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"
    
    # Create Info.plist
    cat > "$APP_DIR/Contents/Info.plist" << EOF
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
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
    
    # Create executable
    cat > "$APP_DIR/Contents/MacOS/Hacktivity" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
exec python3 hacktivity_menubar.py
EOF
    chmod +x "$APP_DIR/Contents/MacOS/Hacktivity"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "🎯 How to use:"
echo "   • Run 'hacktivity' from terminal"
echo "   • Or launch 'Hacktivity.app' from Applications"
echo "   • Or add to Login Items for auto-start"
echo ""
echo "📁 Files installed in: $INSTALL_DIR"
echo "🍎 App bundle created: $APP_DIR"
echo ""
echo "💡 Tip: Add Hacktivity.app to your Login Items in System Preferences"
echo "    to start automatically when you log in."
