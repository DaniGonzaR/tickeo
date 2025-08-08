#!/bin/bash

# Netlify Flutter Build Script
set -e

echo "🚀 Starting Flutter Web Build for Netlify..."

# Install Flutter if not already installed
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    
    # Download and install Flutter
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
    export PATH="$PATH:/opt/flutter/bin"
    
    # Pre-download Dart SDK
    flutter precache --web
    
    echo "✅ Flutter installed successfully"
else
    echo "✅ Flutter already installed"
fi

# Verify Flutter installation
flutter --version
flutter doctor --verbose

# Enable web support
flutter config --enable-web

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🏗️ Building Flutter web app..."
flutter build web --release --web-renderer html

# Copy build output to Netlify's expected directory
echo "📁 Copying build files..."
mkdir -p dist
cp -r build/web/* dist/

echo "🎉 Build completed successfully!"
