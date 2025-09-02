#!/bin/bash
# Convert PNG icons to appropriate formats for TimeDeck

echo "🎨 Converting TimeDeck icons..."

# Create icons directory
mkdir -p icons

# Convert App Icon to different sizes for .icns creation
echo "📱 Creating app icon sizes..."
if command -v sips &> /dev/null; then
    # Create different sizes for .icns
    mkdir -p "icons/TimeDeck.iconset"
    
    # Standard icon sizes for macOS
    sips -z 16 16 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_16x16.png"
    sips -z 32 32 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_16x16@2x.png"
    sips -z 32 32 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_32x32.png" 
    sips -z 64 64 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_32x32@2x.png"
    sips -z 128 128 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_128x128.png"
    sips -z 256 256 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_128x128@2x.png"
    sips -z 256 256 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_256x256.png"
    sips -z 512 512 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_256x256@2x.png"
    sips -z 512 512 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_512x512.png"
    sips -z 1024 1024 "assets/App Icon.png" --out "icons/TimeDeck.iconset/icon_512x512@2x.png"
    
    # Create .icns file
    if command -v iconutil &> /dev/null; then
        iconutil -c icns "icons/TimeDeck.iconset" -o "icons/TimeDeck.icns"
        echo "✅ Created TimeDeck.icns"
    else
        echo "⚠️  iconutil not found, will use PNG fallback"
    fi
else
    echo "⚠️  sips not found, copying original files"
    cp "assets/App Icon.png" "icons/TimeDeck_app.png"
fi

# Create menu bar icon (smaller size)
echo "📊 Creating menu bar icon..."
if command -v sips &> /dev/null; then
    # Menu bar icons should be small (around 22x22 for @1x, 44x44 for @2x)
    sips -z 22 22 "assets/Menubar Icon.png" --out "icons/menubar_icon.png"
    sips -z 44 44 "assets/Menubar Icon.png" --out "icons/menubar_icon@2x.png"
    echo "✅ Created menu bar icons"
else
    cp "assets/Menubar Icon.png" "icons/menubar_icon.png"
fi

# Create DMG background if needed
echo "🖼️  Creating DMG background..."
if command -v sips &> /dev/null; then
    sips -z 400 600 "assets/App Icon.png" --out "icons/dmg_background.png"
fi

echo "🎯 Icon conversion complete!"
echo "Files created:"
ls -la icons/
