#!/bin/bash
# Build standalone executable using PyInstaller

echo "🔨 Building standalone Hacktivity executable..."

# Check if PyInstaller is installed
if ! python3 -c "import PyInstaller" 2>/dev/null; then
    echo "📦 Installing PyInstaller..."
    python3 -m pip install pyinstaller
fi

# Install dependencies first
python3 -m pip install -r requirements.txt

# Create the executable
echo "⚙️ Creating executable..."
python3 -m PyInstaller \
    --onefile \
    --windowed \
    --noconsole \
    --name "Hacktivity" \
    --icon=hacktivity.icns \
    --add-data "*.applescript:." \
    --hidden-import="rumps" \
    --hidden-import="Foundation" \
    --hidden-import="AppKit" \
    hacktivity_menubar.py

# Create distribution folder
mkdir -p dist_standalone
cp dist/Hacktivity dist_standalone/
cp *.applescript dist_standalone/
cp README.md dist_standalone/

# Create simple launcher instructions
cat > dist_standalone/README.txt << 'EOF'
# Hacktivity Standalone

## Installation:
1. Copy the "Hacktivity" executable and .applescript files to any folder
2. Double-click "Hacktivity" to run
3. Look for the 📊 icon in your menu bar

## Auto-start:
- Add "Hacktivity" to Login Items in System Preferences > Users & Groups

No Python installation required!
EOF

echo "✅ Standalone executable created!"
echo "📁 Files in: dist_standalone/"
echo "🚀 Run: ./dist_standalone/Hacktivity"
