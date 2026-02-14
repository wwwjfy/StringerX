#!/bin/bash

# Build StringerX from command line
# This script properly resolves Swift Package Manager dependencies

echo "🔧 Building StringerX..."
echo ""

# Method 1: Using scheme (recommended)
echo "Building with scheme..."
xcodebuild \
  -project StringerX.xcodeproj \
  -scheme StringerX \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath ./build \
  build

# Check if build succeeded
if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Build successful!"
  echo "📦 App location: ./build/Build/Products/Debug/StringerX.app"
else
  echo ""
  echo "❌ Build failed"
  exit 1
fi
