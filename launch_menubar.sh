#!/bin/bash
# Launch script for TimeDeck Menu Bar App

cd "$(dirname "$0")"

# Check if rumps is installed
if ! python3 -c "import rumps" 2>/dev/null; then
    echo "Installing rumps..."
    # Use python3 -m pip to ensure we install for the correct Python version
    python3 -m pip install -r requirements.txt
fi

# Launch the menu bar app
python3 timedeck_menubar.py
