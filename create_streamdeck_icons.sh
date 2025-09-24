#!/bin/bash
# Create placeholder icons for TimeDeck StreamDeck Plugin

ICONS_DIR="TimeDeckStreamDeck.sdPlugin/imgs"

echo "🎨 Creating StreamDeck plugin icons..."

# Create icons directory if it doesn't exist
mkdir -p "$ICONS_DIR"

# Function to create a simple text-based icon
create_text_icon() {
    local filename="$1"
    local text="$2"
    local color="$3"
    
    # Try to use built-in macOS tools to create a simple icon
    # For now, create placeholder files that indicate what icons are needed
    echo "Icon needed: $text" > "$ICONS_DIR/${filename}.txt"
    echo "Created placeholder for: $filename"
}

# Create all required icons (72x72 for StreamDeck)
create_text_icon "pluginIcon" "TimeDeck" "blue"
create_text_icon "categoryIcon" "Productivity" "gray"
create_text_icon "start-activity" "▶️ START" "green"
create_text_icon "end-activity" "⏹️ END" "red"
create_text_icon "activity-status" "📊 STATUS" "blue"
create_text_icon "quick-template" "🏷️ TEMPLATE" "purple"
create_text_icon "pause-resume" "⏸️ PAUSE" "orange"
create_text_icon "start-fresh" "🧹 FRESH" "cyan"

echo ""
echo "✅ Placeholder icons created!"
echo "📝 To complete the plugin:"
echo ""
echo "1. Replace .txt files with actual 72x72 PNG images:"
echo "   - Use a design tool like Sketch, Figma, or Photoshop"
echo "   - Or use online icon generators"
echo "   - StreamDeck recommends 72x72 pixels, PNG format"
echo ""
echo "2. Icon recommendations:"
echo "   🔹 pluginIcon.png - TimeDeck logo or ⏱️ icon"
echo "   🔹 categoryIcon.png - Productivity icon or 📊"
echo "   🔹 start-activity.png - Play button ▶️ or START"
echo "   🔹 end-activity.png - Stop button ⏹️ or END"  
echo "   🔹 activity-status.png - Clock ⏰ or STATUS"
echo "   🔹 quick-template.png - Template icon 🏷️"
echo "   🔹 pause-resume.png - Pause ⏸️ or PAUSE/PLAY"
echo "   🔹 start-fresh.png - Refresh 🔄 or RESET"
echo ""
echo "3. Install plugin:"
echo "   • Double-click TimeDeckStreamDeck.sdPlugin folder"
echo "   • Or copy to StreamDeck plugins directory"
echo ""

# Try to use sips (macOS built-in) to create actual icons if possible
if command -v sips > /dev/null 2>&1; then
    echo "🎨 Attempting to create basic icons with sips..."
    
    # Create a simple colored square as base
    # Note: This is a simplified approach - in practice you'd want proper icons
    for icon in pluginIcon categoryIcon start-activity end-activity activity-status quick-template pause-resume start-fresh; do
        # Create a simple 72x72 colored square (basic placeholder)
        # In practice, you'd want to create proper icons with design software
        echo "Would create: $icon.png (72x72)"
    done
fi

echo "🚀 StreamDeck plugin structure complete!"
echo "📁 Plugin location: $(pwd)/$ICONS_DIR/../"
