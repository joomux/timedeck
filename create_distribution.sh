#!/bin/bash
# Create distribution package for Hacktivity

echo "📦 Creating Hacktivity distribution package..."

# Create dist directory
mkdir -p dist
cd dist

# Copy all necessary files
cp ../*.applescript .
cp ../hacktivity_menubar.py .
cp ../requirements.txt .
cp ../launch_menubar.sh .
cp ../install.sh .
cp ../README.md .

# Create simple README for distribution
cat > INSTALL.md << 'EOF'
# Hacktivity Installation

## Quick Install (Recommended)
```bash
./install.sh
```

## Manual Install
1. Ensure Python 3 is installed
2. Install dependencies: `python3 -m pip install -r requirements.txt`
3. Run: `python3 hacktivity_menubar.py`

## What you get:
- 📊 Menu bar app for activity tracking
- 🔧 AppleScript files for manual use
- 📈 Automatic time tracking and reporting

After installation, look for the 📊 icon in your menu bar!
EOF

# Create version info
echo "1.0.0" > VERSION

echo "✅ Distribution created in dist/ folder"
echo ""
echo "📤 To share with others:"
echo "   1. Zip the dist/ folder"
echo "   2. Share the zip file"
echo "   3. Recipients run: unzip hacktivity.zip && cd dist && ./install.sh"
