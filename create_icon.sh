#!/bin/bash
# Create a simple icon for Hacktivity using built-in macOS tools

echo "🎨 Creating Hacktivity icon..."

# Create icon using sf symbols or fallback to text
if command -v sips &> /dev/null; then
    # Create a simple 512x512 icon with text
    # This requires macOS built-in tools
    
    # Create a temporary PNG with text
    cat > temp_icon.svg << 'EOF'
<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
  <rect width="512" height="512" fill="#2563eb" rx="80"/>
  <text x="256" y="300" font-family="SF Pro Display, Arial" font-size="200" fill="white" text-anchor="middle">📊</text>
  <text x="256" y="450" font-family="SF Pro Display, Arial" font-size="48" fill="white" text-anchor="middle">Hacktivity</text>
</svg>
EOF

    # Convert SVG to PNG if possible
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w 512 -h 512 temp_icon.svg -o icon_512.png
        echo "✅ Icon created: icon_512.png"
    elif command -v qlmanage &> /dev/null; then
        # Use Quick Look to generate preview (macOS fallback)
        qlmanage -t -s 512 temp_icon.svg -o .
        mv temp_icon.svg.png icon_512.png 2>/dev/null || echo "⚠️  Icon generation partially successful"
    else
        echo "ℹ️  No SVG converter found. Using emoji as icon."
        # Fallback: create a simple text file that explains the icon
        echo "📊 Hacktivity Icon" > icon_placeholder.txt
        echo "Use this emoji or create a proper .icns file" >> icon_placeholder.txt
    fi
    
    # Clean up
    rm -f temp_icon.svg
    
    echo "💡 To use a custom icon:"
    echo "   1. Create a 512x512 PNG image"
    echo "   2. Convert to .icns using Icon Composer or online tools"
    echo "   3. Replace the icon in the app bundle"
    
else
    echo "⚠️  sips not found. Creating text placeholder."
    echo "📊 Hacktivity" > icon_placeholder.txt
fi
