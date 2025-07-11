#!/bin/bash

# Build and Release Script for Notetaker
# This script builds the app, creates a DMG, and generates the appcast

set -e  # Exit on any error

# Configuration
APP_NAME="Notetaker"
BUNDLE_ID="owen.notetaker"
VERSION=$(grep -m1 "MARKETING_VERSION" notetaker.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/')
SIGN_ID="-"   # always use an ad-hoc signature

if [ -z "$VERSION" ]; then
    echo "❌ Could not determine version from project file"
    echo "   Make sure notetaker.xcodeproj/project.pbxproj exists and contains MARKETING_VERSION"
    exit 1
fi
BUILD_DIR="$(pwd)/build"
RELEASES_DIR="$(pwd)/releases"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "🚀 Building ${APP_NAME} v${VERSION}..."

# Clean and build a *universal* binary (arm64 + x86_64)
# -----------------------------------------------------
# Xcode will only build the active architecture by default ("My Mac") which results in an
# Apple-silicon-only binary when run on an M-series machine. By explicitly passing both
# architectures and using the generic macOS destination we ensure a universal build.
# The resulting binary is produced at the usual DerivedData location so the rest of the
# script can continue to reference $APP_PATH unchanged.

ARCHS="arm64 x86_64"

echo "📦 Building universal app (archs: $ARCHS)..."
xcodebuild \
  -project notetaker.xcodeproj \
  -scheme notetaker \
  -configuration Release \
  -derivedDataPath "${BUILD_DIR}" \
  -destination 'generic/platform=macOS' \
  ARCHS="$ARCHS" \
  ONLY_ACTIVE_ARCH=NO \
  clean build

# Find the built app
APP_PATH="${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH"
    exit 1
fi

# 🔏 Code-sign the app (ad-hoc) -------------------------------------------------

echo "🔏 Ad-hoc signing (.app + embedded frameworks)"
codesign \
  --force \
  --deep \
  --sign - \
  "$APP_PATH"

# Validate the signature before packaging
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "✅ App built successfully at $APP_PATH"

# Create DMG
echo "📀 Creating DMG..."
mkdir -p "$RELEASES_DIR"

# Remove old DMG if it exists
if [ -f "$RELEASES_DIR/$DMG_NAME" ]; then
    rm "$RELEASES_DIR/$DMG_NAME"
fi

# Create DMG using create-dmg
create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 200 190 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 600 185 \
    "$RELEASES_DIR/$DMG_NAME" \
    "$APP_PATH"

echo "✅ DMG created: $RELEASES_DIR/$DMG_NAME"

# Generate appcast
echo "📡 Generating appcast..."
/opt/homebrew/Caskroom/sparkle/2.7.1/bin/generate_appcast "$RELEASES_DIR" \
    --download-url-prefix "https://github.com/owengretzinger/notetaker/releases/download/v${VERSION}/" \
    -o "appcast.xml"

echo "✅ Appcast generated: appcast.xml"

# Show file sizes
echo ""
echo "📊 Release Summary:"
echo "   Version: $VERSION"
echo "   DMG: $DMG_NAME ($(du -h "$RELEASES_DIR/$DMG_NAME" | cut -f1))"
echo "   Location: $RELEASES_DIR/$DMG_NAME"
echo ""
echo "🎉 Release ready! Next steps:"
echo "   1. Test the DMG on another Mac"
echo "   2. Create a GitHub release with tag v${VERSION}"
echo "   3. Upload the DMG to the GitHub release"
echo "   4. Commit and push the appcast.xml file"
echo "   5. Your users will get auto-update notifications!" 