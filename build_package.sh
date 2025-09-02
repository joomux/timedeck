#!/bin/bash
# Build pip-installable package

echo "📦 Building Hacktivity pip package..."

# Clean previous builds
rm -rf build/ dist/ *.egg-info/

# Install build dependencies
python3 -m pip install --upgrade build twine

# Build the package
python3 -m build

echo "✅ Package built successfully!"
echo ""
echo "📁 Distribution files:"
ls -la dist/

echo ""
echo "🚀 To install locally:"
echo "   pip3 install dist/hacktivity-*.whl"
echo ""
echo "📤 To publish to PyPI:"
echo "   twine upload dist/*"
echo ""
echo "💡 After installation, users can run:"
echo "   hacktivity"
