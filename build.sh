#!/bin/bash

# Netlify Flutter Build Script
set -e

echo "🚀 Starting Flutter Web Build for Netlify..."

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
$FLUTTER_CMD --version
$FLUTTER_CMD doctor --verbose

# Enable web support
$FLUTTER_CMD config --enable-web

# Get dependencies
echo "📦 Getting Flutter dependencies..."
$FLUTTER_CMD pub get

# Build for web
echo "🏗️ Building Flutter web app..."
$FLUTTER_CMD build web --release --web-renderer html

# Copy build output to Netlify's expected directory
echo "📁 Copying build files..."
mkdir -p dist
cp -r build/web/* dist/

echo "🎉 Build completed successfully!"
