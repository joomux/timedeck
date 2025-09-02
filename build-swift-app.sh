#!/bin/bash
# Build script for Swift Hacktivity Menu Bar App

echo "Building Hacktivity Menu Bar App..."

# Create build directory
mkdir -p build

# Compile the Swift app
swiftc -o build/HacktivityMenuBar HacktivityMenuBar.swift -framework Cocoa

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "Run the app with: ./build/HacktivityMenuBar"
    echo ""
    echo "To install permanently:"
    echo "1. Copy ./build/HacktivityMenuBar to /usr/local/bin/"
    echo "2. Add to Login Items in System Preferences"
else
    echo "❌ Build failed!"
fi
