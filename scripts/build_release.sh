#!/bin/bash

# Build and Release Script for Meetingnotes
# This script builds the app, creates a DMG, and generates the appcast

set -e  # Exit on any error

# Configuration
APP_NAME="Meetingnotes"
BUNDLE_ID="owen.meetingnotes"
VERSION=$(grep -m1 "MARKETING_VERSION" Meetingnotes.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/')

# Production code signing configuration
DEVELOPER_ID="${DEVELOPER_ID:-}"

# Notarization configuration (required for production builds)
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

if [ -z "$VERSION" ]; then
    echo "❌ Could not determine version from project file"
    echo "   Make sure Meetingnotes.xcodeproj/project.pbxproj exists and contains MARKETING_VERSION"
    exit 1
fi

BUILD_DIR="$(pwd)/build"
RELEASES_DIR="$(pwd)/releases"
# New: keep each release in its own sub-folder (e.g. releases/v1.0.2)
VERSION_DIR="${RELEASES_DIR}/v${VERSION}"
mkdir -p "$VERSION_DIR"

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
# Absolute paths for the artifacts
DMG_PATH="${VERSION_DIR}/${DMG_NAME}"
ZIP_PATH="${VERSION_DIR}/${ZIP_NAME}"

echo "🚀 Building ${APP_NAME} v${VERSION}..."

# Check signing configuration
echo "🔏 Using Developer ID Application: [HIDDEN]"

# Verify notarization credentials
if [ -z "$DEVELOPER_ID" ] || [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_PASSWORD" ]; then
    echo "❌ Missing required credentials!"
    echo ""
    echo "📝 Required environment variables:"
    echo "   DEVELOPER_ID   - Your Developer ID Application certificate name"
    echo "   APPLE_ID       - Your Apple ID email"
    echo "   TEAM_ID        - Your Apple Developer Team ID"
    echo "   APP_PASSWORD   - App-specific password"
    echo ""
    echo "🔧 Set them up:"
    echo "   Create a .env file with your credentials"
    echo "   Then run: source .env && ./scripts/build_release.sh"
    echo ""
    echo "💡 Use: ./scripts/setup_codesigning.sh to get started"
    echo ""
    exit 1
fi

echo "📡 Notarization configured for Apple ID: [HIDDEN]"
echo "🏷️  Team ID: [HIDDEN]"

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
  -project Meetingnotes.xcodeproj \
  -scheme meetingnotes \
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

# 🔏 Production code signing with hardened runtime -------------------------------------------------

echo "🔏 Code signing all embedded frameworks and components..."

# Sign all embedded frameworks and their components first
# This is required for notarization - we must sign from the inside out
find "$APP_PATH" -name "*.framework" -type d | while read framework; do
    echo "   Signing framework: $(basename "$framework")"
    
    # Sign all binaries within the framework
    find "$framework" -type f -perm +111 -exec sh -c 'file "$1" | grep -q "Mach-O"' _ {} \; -print | while read binary; do
        echo "      Signing binary: $(basename "$binary")"
        codesign \
          --force \
          --options runtime \
          --sign "$DEVELOPER_ID" \
          --timestamp \
          "$binary"
    done
    
    # Sign the framework itself
    codesign \
      --force \
      --options runtime \
      --sign "$DEVELOPER_ID" \
      --timestamp \
      "$framework"
done

# Sign all XPC services
find "$APP_PATH" -name "*.xpc" -type d | while read xpc; do
    echo "   Signing XPC service: $(basename "$xpc")"
    codesign \
      --force \
      --options runtime \
      --sign "$DEVELOPER_ID" \
      --timestamp \
      "$xpc"
done

# Sign all nested apps (like Sparkle's Updater.app)
find "$APP_PATH" -name "*.app" -type d | grep -v "^$APP_PATH$" | while read app; do
    echo "   Signing nested app: $(basename "$app")"
    codesign \
      --force \
      --options runtime \
      --sign "$DEVELOPER_ID" \
      --timestamp \
      "$app"
done

echo "🔏 Code signing the main app with hardened runtime..."
codesign \
  --force \
  --options runtime \
  --entitlements "meetingnotes/meetingnotes.entitlements" \
  --sign "$DEVELOPER_ID" \
  --timestamp \
  "$APP_PATH"

# Validate the signature before packaging
echo "✅ Validating code signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "✅ App built and signed successfully at $APP_PATH"

# Create DMG
echo "📀 Creating DMG..."
# Remove old DMG if it exists
if [ -f "$DMG_PATH" ]; then
    rm "$DMG_PATH"
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
    "$DMG_PATH" \
    "$APP_PATH"

echo "✅ DMG created: $DMG_PATH"

# 🔖 -------------------------------------------------
# NEW: Create a ZIP archive for Sparkle auto-updates
# --------------------------------------------------
ZIP_NAME="${APP_NAME}-${VERSION}.zip"

echo "📦 Creating ZIP archive for Sparkle auto-updates..."
# Keep parent so the archive extracts directly to the app bundle
# ditto preserves resource forks and extended attributes that Gatekeeper expects

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "✅ ZIP created: $ZIP_PATH"

# 📡 Notarization (required for all production builds)
echo "📡 Starting notarization process..."

# Submit for notarization
echo "📤 Submitting DMG for notarization..."
NOTARIZATION_RESPONSE=$(xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait)

if echo "$NOTARIZATION_RESPONSE" | grep -q "status: Accepted"; then
    echo "✅ Notarization successful!"
    
    # Staple the notarization
    echo "📎 Stapling notarization ticket to DMG..."
    xcrun stapler staple "$DMG_PATH"
    echo "✅ DMG notarized and stapled!"
else
    echo "❌ Notarization failed!"
    echo "$NOTARIZATION_RESPONSE"
    exit 1
fi

# Generate appcast with signatures - only process current version to avoid URL corruption
# -----------------------------------------------------------------------------
# We only want the .zip in our appcast. Move DMGs out temporarily so they are
# not picked up by generate_appcast.

echo "📡 Generating appcast with EdDSA signatures (ZIP only)..."

# Stage ZIPs into a temporary workspace so generate_appcast sees every version
APPCAST_WORK="${RELEASES_DIR}/appcast_work"
rm -rf "$APPCAST_WORK"
mkdir -p "$APPCAST_WORK"

echo "🔗 Staging ZIP archives for appcast generation..."
find "$RELEASES_DIR" -type f -name "*.zip" -exec ln -sf {} "$APPCAST_WORK/" \;

/opt/homebrew/Caskroom/sparkle/2.7.1/bin/generate_appcast "$APPCAST_WORK" \
    --download-url-prefix "https://github.com/owengretzinger/meetingnotes/releases/download/v${VERSION}/" \
    -o "appcast.xml"

echo "🚚 Moving generated delta files into version folder..."
if compgen -G "$APPCAST_WORK/*.delta" > /dev/null; then
    mv "$APPCAST_WORK"/*.delta "$VERSION_DIR/"
fi

rm -rf "$APPCAST_WORK"

echo "📝 Note: Make sure to upload the DMG to GitHub releases with the correct tag (v${VERSION})"

echo "✅ Appcast generated: appcast.xml"

# Show file sizes
echo ""
echo "📊 Release Summary:"
echo "   Version: $VERSION"
echo "   ZIP: $ZIP_NAME ($(du -h "$ZIP_PATH" | cut -f1))"
echo "   DMG: $DMG_NAME ($(du -h "$DMG_PATH" | cut -f1))"
echo "   Location: $VERSION_DIR"
echo "   Code Signing: ✅ Production (Owen's Developer ID)"
echo "   Notarization (DMG): ✅ Complete"
echo ""
echo "🎉 Production release ready! Next steps:"
echo "   1. Test the DMG on another Mac"
echo "   2. Create a GitHub release with tag v${VERSION}"
echo "   3. Upload the DMG to the GitHub release"
echo "   4. Commit and push the appcast.xml file"
echo "   5. Your users will get auto-update notifications!" 