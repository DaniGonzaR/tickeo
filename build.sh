#!/bin/bash

# Netlify Flutter Build Script
set -e  # Exit on any error
set -x  # Print commands as they are executed

echo "🚀 Starting Flutter Web Build for Netlify..."
echo "📍 Current directory: $(pwd)"
echo "📍 Available space: $(df -h . | tail -1 | awk '{print $4}')"
echo "📍 Git status: $(git log --oneline -1 || echo 'No git info available')"

# Install Flutter if not already installed
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    
    # Create local flutter directory in build workspace
    FLUTTER_DIR="$PWD/flutter"
    
    # Download and install Flutter in local directory
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
    export PATH="$PATH:$FLUTTER_DIR/bin"
    
    # Verify Flutter is accessible
    "$FLUTTER_DIR/bin/flutter" --version
    
    # Pre-download Dart SDK for web
    "$FLUTTER_DIR/bin/flutter" precache --web
    
    echo "✅ Flutter installed successfully in $FLUTTER_DIR"
else
    echo "✅ Flutter already installed"
fi

# Set Flutter path for subsequent commands
if [ -d "$PWD/flutter" ]; then
    export PATH="$PATH:$PWD/flutter/bin"
    FLUTTER_CMD="$PWD/flutter/bin/flutter"
else
    FLUTTER_CMD="flutter"
fi

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
$FLUTTER_CMD --version || { echo "❌ Flutter version check failed"; exit 1; }
echo "🔍 Running Flutter doctor..."
$FLUTTER_CMD doctor --verbose || echo "⚠️ Flutter doctor completed with warnings (continuing)"

# Enable web support
echo "🌐 Enabling Flutter web support..."
$FLUTTER_CMD config --enable-web || { echo "❌ Failed to enable web support"; exit 1; }

# Get dependencies
echo "📦 Getting Flutter dependencies..."
$FLUTTER_CMD pub get || { echo "❌ Failed to get dependencies"; exit 1; }

# Clean any previous builds
echo "🧹 Cleaning previous builds..."
$FLUTTER_CMD clean || echo "⚠️ Clean command failed (continuing)"

# Build for web
echo "🏗️ Building Flutter web app..."
$FLUTTER_CMD build web --release || { echo "❌ Flutter web build failed"; exit 1; }

# Verify build output exists
if [ ! -d "build/web" ]; then
    echo "❌ Build output directory not found!"
    exit 1
fi

echo "✅ Build completed successfully"
echo "📊 Build output size: $(du -sh build/web | cut -f1)"

# Copy build output to Netlify's expected directory
echo "📁 Copying build files to dist directory..."
mkdir -p dist || { echo "❌ Failed to create dist directory"; exit 1; }
cp -r build/web/* dist/ || { echo "❌ Failed to copy build files"; exit 1; }

# Verify dist directory has content
if [ ! -f "dist/index.html" ]; then
    echo "❌ index.html not found in dist directory!"
    ls -la dist/ || echo "❌ Cannot list dist directory"
    exit 1
fi

echo "✅ Files copied successfully"
echo "📊 Dist directory size: $(du -sh dist | cut -f1)"
echo "📋 Dist directory contents:"
ls -la dist/ | head -10

echo "🎉 Build completed successfully!"
