#!/bin/bash

# Get user's activity templates via HTTP API and show selection menu
echo "🎯 TimeDeck - Start Activity"
echo "=========================="

# Check if TimeDeck is running by testing the API
if ! curl -s "http://localhost:8080/api/health" > /dev/null 2>&1; then
    echo "❌ TimeDeck is not running or API is not available"
    echo "Please start TimeDeck and try again."
    exit 1
fi

# Get templates from API
templates_json=$(curl -s "http://localhost:8080/api/templates")
if [ $? -ne 0 ]; then
    echo "❌ Failed to get templates from TimeDeck"
    exit 1
fi

# Extract template names from nested JSON structure (no jq dependency)
# The API returns: {"data": {"templates": [{"name": "...", ...}, ...]}}
template_names=$(echo "$templates_json" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"name"[[:space:]]*:[[:space:]]*"//g' | sed 's/"//g')

if [ -z "$template_names" ]; then
    echo "❌ No templates found. Please create templates in TimeDeck first."
    exit 1
fi

echo "Available activities:"
echo "-------------------"

# Create numbered list
counter=1
while IFS= read -r template; do
    echo "$counter. $template"
    counter=$((counter + 1))
done <<< "$template_names"

echo
echo "0. Cancel"
echo
read -p "Select activity (number): " choice

# Handle selection
if [ "$choice" = "0" ]; then
    echo "Cancelled."
    exit 0
fi

# Get the selected template name
selected_template=$(echo "$template_names" | sed -n "${choice}p")

if [ -z "$selected_template" ]; then
    echo "❌ Invalid selection"
    exit 1
fi

echo "🚀 Starting activity: $selected_template"
open "timedeck://start/$selected_template"
