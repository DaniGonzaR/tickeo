#!/bin/bash

# Netlify Flutter Build Script
set -e  # Exit on any error
set -x  # Print commands as they are executed

# Function to handle errors
handle_error() {
    echo "❌ Build failed at line $1"
    echo "❌ Last command: $2"
    echo "❌ Error code: $3"
    exit 1
}

# Trap errors
trap 'handle_error $LINENO "$BASH_COMMAND" $?' ERR

echo "🚀 Starting Flutter Web Build for Netlify..."
echo "📍 Current directory: $(pwd)"
echo "📍 Available space: $(df -h . | tail -1 | awk '{print $4}' || echo 'Unknown')"
echo "📍 Git status: $(git log --oneline -1 2>/dev/null || echo 'No git info available')"
echo "📍 Environment: $(uname -a)"
echo "📍 Node version: $(node --version 2>/dev/null || echo 'Node not found')"
echo "📍 Git version: $(git --version 2>/dev/null || echo 'Git not found')"

# Install Flutter if not already installed
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    
    # Create local flutter directory in build workspace
    FLUTTER_DIR="$PWD/flutter"
    echo "📍 Flutter will be installed in: $FLUTTER_DIR"
    
    # Clean any existing flutter directory
    if [ -d "$FLUTTER_DIR" ]; then
        echo "🧹 Cleaning existing Flutter directory..."
        rm -rf "$FLUTTER_DIR"
    fi
    
    # Download and install Flutter in local directory with timeout
    echo "⬇️ Cloning Flutter repository..."
    timeout 300 git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR" || {
        echo "❌ Flutter clone timed out or failed"
        exit 1
    }
    
    # Verify directory was created
    if [ ! -d "$FLUTTER_DIR" ]; then
        echo "❌ Flutter directory was not created"
        exit 1
    fi
    
    export PATH="$PATH:$FLUTTER_DIR/bin"
    echo "📍 Updated PATH: $PATH"
    
    # Verify Flutter is accessible
    echo "🔍 Verifying Flutter installation..."
    "$FLUTTER_DIR/bin/flutter" --version || {
        echo "❌ Flutter version check failed"
        exit 1
    }
    
    # Pre-download Dart SDK for web with timeout
    echo "⬇️ Pre-downloading Dart SDK for web..."
    timeout 300 "$FLUTTER_DIR/bin/flutter" precache --web || {
        echo "❌ Flutter precache failed or timed out"
        exit 1
    }
    
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
