#!/bin/bash

# Build and Release Script for Meetingnotes
# This script builds the app, creates a DMG, and generates the appcast

set -e  # Exit on any error

# Configuration
APP_NAME="Meetingnotes"
BUNDLE_ID="owen.meetingnotes"
VERSION=$(grep -m1 "MARKETING_VERSION" Meetingnotes.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/')

# Source environment variables if .env file exists
if [ -f ".env" ]; then
    echo "📄 Loading environment variables from .env file..."
    source .env
fi

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

DMG_NAME="${APP_NAME}.dmg"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
# Absolute paths for the artifacts
DMG_PATH="${VERSION_DIR}/${DMG_NAME}"
ZIP_PATH="${VERSION_DIR}/${ZIP_NAME}"

echo "🚀 Building ${APP_NAME} v${VERSION}..."

# Check signing configuration
echo "🔏 Using Developer ID Application: $DEVELOPER_ID"

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
    echo "   Then run: ./scripts/build_release.sh"
    echo ""
    echo "💡 Use: ./scripts/setup_codesigning.sh to get started"
    echo ""
    exit 1
fi

echo "📡 Notarization configured for Apple ID: $APPLE_ID"
echo "🏷️  Team ID: $TEAM_ID"

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

# Prepare a staging directory so the .zip contains only
# `${APP_NAME}.app` at its root (without the intermediate "Release"
# folder that Xcode places it in). Sparkle's `generate_appcast`
# expects this structure – otherwise it cannot locate the app's
# executable when unarchiving which leads to the "ditto: ... No such
# file or directory / Could not unarchive ... Code=3000" error we saw.
STAGING_DIR="${BUILD_DIR}/zip_staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ZIP_INPUT_PATH="${STAGING_DIR}/${APP_NAME}.app"

echo "📦 Creating ZIP archive for Sparkle auto-updates..."
(
  cd "$STAGING_DIR"
  echo "[DEBUG] Running: ditto -c -k --sequesterRsrc --keepParent $APP_NAME.app $ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$ZIP_PATH"
)

# Clean up staging folder
rm -rf "$STAGING_DIR"

echo "✅ ZIP created: $ZIP_PATH"

# --- Advanced ZIP validation ---
TMP_EXTRACT_DIR="${BUILD_DIR}/zip_extract_test"
rm -rf "$TMP_EXTRACT_DIR"
mkdir -p "$TMP_EXTRACT_DIR"
echo "[DEBUG] Testing ZIP extraction with: ditto -x -k $ZIP_PATH $TMP_EXTRACT_DIR"
if ditto -x -k "$ZIP_PATH" "$TMP_EXTRACT_DIR"; then
  if [ -f "$TMP_EXTRACT_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" ]; then
    echo "✅ [DEBUG] ZIP extraction succeeded, executable present."
  else
    echo "❌ [ERROR] ZIP extracted, but $APP_NAME.app/Contents/MacOS/$APP_NAME not found!"
    echo "[DEBUG] Directory listing after extraction:"
    find "$TMP_EXTRACT_DIR" | sed 's/^/    /'
    rm -rf "$TMP_EXTRACT_DIR"
    exit 2
  fi
else
  echo "❌ [ERROR] Failed to extract ZIP with ditto!"
  echo "[DEBUG] Attempting to list ZIP contents:"
  unzip -l "$ZIP_PATH" || echo "[ERROR] unzip failed"
  rm -rf "$TMP_EXTRACT_DIR"
  exit 2
fi
rm -rf "$TMP_EXTRACT_DIR"

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
echo "[DEBUG] Staging all ZIP archives from all versions..."
find "$RELEASES_DIR" -maxdepth 2 -type f -name "*.zip" -exec cp {} "$APPCAST_WORK"/ \;

echo "[DEBUG] Staging all existing delta files to preserve them..."
find "$RELEASES_DIR" -maxdepth 2 -type f -name "*.delta" -exec cp {} "$APPCAST_WORK"/ \;

echo "[DEBUG] Appcast workdir contents:"
ls -la "$APPCAST_WORK"
echo "[DEBUG] Running generate_appcast..."
/opt/homebrew/Caskroom/sparkle/2.7.1/bin/generate_appcast "$APPCAST_WORK" \
    -o "appcast.xml" 2>&1 | tee "$BUILD_DIR/generate_appcast.log"

if grep -q "Could not unarchive" "$BUILD_DIR/generate_appcast.log"; then
  echo "❌ [ERROR] generate_appcast encountered unarchive failures!"
  echo "   See log: $BUILD_DIR/generate_appcast.log"
  exit 3
fi

echo "🔧 Fixing download URLs in appcast.xml..."
# Fix ZIP/DMG URLs to include version folder
# Transform "https://github.com/.../download/Meetingnotes-1.0.3.zip" to "https://github.com/.../download/v1.0.3/Meetingnotes-1.0.3.zip"
sed -i '' -E 's|url="([^"]*/download/)(Meetingnotes-([0-9]+\.[0-9]+\.[0-9]+)\.(zip\|dmg))"|url="\1v\3/\2"|g' appcast.xml

# Fix delta URLs - they need to be in the version folder of the release they belong to
# We'll need to parse the appcast to figure out which version each delta belongs to
python3 << 'EOF'
import xml.etree.ElementTree as ET
import re

# Parse the appcast
tree = ET.parse('appcast.xml')
root = tree.getroot()

# Register namespace to preserve it in output
ET.register_namespace('sparkle', 'http://www.andymatuschak.org/xml-namespaces/sparkle')

# Process each item
for item in root.findall('.//item'):
    # Get the version for this item
    version_elem = item.find('.//{http://www.andymatuschak.org/xml-namespaces/sparkle}shortVersionString')
    if version_elem is not None:
        version = version_elem.text
        
        # Fix all delta URLs within this item's sparkle:deltas section
        deltas_elem = item.find('.//{http://www.andymatuschak.org/xml-namespaces/sparkle}deltas')
        if deltas_elem is not None:
            for enclosure in deltas_elem.findall('.//enclosure[@url]'):
                url = enclosure.get('url')
                if url and '.delta' in url:
                    # Extract just the filename
                    filename = url.split('/')[-1]
                    # Set the correct URL with version folder
                    new_url = f'https://github.com/owengretzinger/meetingnotes/releases/download/v{version}/{filename}'
                    enclosure.set('url', new_url)

        # Fix the main enclosure URL (ZIP/DMG) to point to the GitHub release asset
        main_enclosure = item.find('enclosure')
        if main_enclosure is not None:
            url = main_enclosure.get('url')
            if url:
                filename = url.split('/')[-1]
                new_url = f'https://github.com/owengretzinger/meetingnotes/releases/download/v{version}/{filename}'
                main_enclosure.set('url', new_url)

# Write the fixed appcast
tree.write('appcast.xml', encoding='UTF-8', xml_declaration=True)

# Add back the standalone attribute
with open('appcast.xml', 'r') as f:
    content = f.read()
content = content.replace('<?xml version=\'1.0\' encoding=\'UTF-8\'?>', '<?xml version="1.0" standalone="yes"?>')
with open('appcast.xml', 'w') as f:
    f.write(content)
EOF

echo "🚚 Moving only NEW delta files into version folder..."
# Get the build number from the project
BUILD_NUMBER=$(grep -m1 "CURRENT_PROJECT_VERSION" Meetingnotes.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/')
if compgen -G "$APPCAST_WORK/${APP_NAME}${BUILD_NUMBER}-"*.delta > /dev/null 2>&1; then
    echo "[DEBUG] Moving new delta files for build $BUILD_NUMBER..."
    mv "$APPCAST_WORK/${APP_NAME}${BUILD_NUMBER}-"*.delta "$VERSION_DIR/" 2>/dev/null || true
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