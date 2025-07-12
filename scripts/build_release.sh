#!/bin/bash
# Build and Release Script for Meetingnotes

set -e

# Configuration
PROJECT_NAME="meetingnotes"
APP_NAME="Meetingnotes"
BUNDLE_ID="owen.meetingnotes"
VERSION=$(grep -m1 "MARKETING_VERSION" meetingnotes.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/')

# Validation
if [ -z "$VERSION" ]; then
   echo "❌ Error: Could not extract version from project file"
   echo "   Make sure meetingnotes.xcodeproj/project.pbxproj exists and contains MARKETING_VERSION"
   exit 1
fi

echo "🏗️  Building $APP_NAME v$VERSION..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
rm -rf DerivedData/
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Create build directory
mkdir -p build

# Build the app
echo "📦 Building Release..."
xcodebuild clean build \
-project meetingnotes.xcodeproj \
-scheme meetingnotes \
-configuration Release \
-derivedDataPath ./DerivedData \
-archivePath ./build/${APP_NAME}.xcarchive \
CODE_SIGN_IDENTITY="" \
CODE_SIGNING_REQUIRED=NO \
CODE_SIGNING_ALLOWED=NO

# Create the app bundle
echo "📱 Creating app bundle..."
APP_PATH="./DerivedData/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
   echo "❌ Error: App bundle not found at $APP_PATH"
   exit 1
fi

# Copy app to build directory
cp -R "$APP_PATH" "./build/"

# Create DMG
echo "� Creating DMG..."
DMG_NAME="${APP_NAME}-${VERSION}"
DMG_PATH="./build/${DMG_NAME}.dmg"

# Remove existing DMG if it exists
rm -f "$DMG_PATH"

# Create DMG
hdiutil create -srcfolder "./build/${APP_NAME}.app" -volname "$APP_NAME" -fs HFS+ -format UDZO "$DMG_PATH"

# Verify DMG was created
if [ ! -f "$DMG_PATH" ]; then
   echo "❌ Error: DMG creation failed"
   exit 1
fi

echo "✅ Build completed successfully!"
echo "📁 DMG created: $DMG_PATH"
echo "📏 DMG size: $(du -h "$DMG_PATH" | cut -f1)"

# Generate appcast XML
echo "📡 Generating appcast XML..."
APPCAST_PATH="./appcast.xml"
DMG_SIZE=$(stat -f%z "$DMG_PATH")
CURRENT_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

# Create appcast XML
cat > "$APPCAST_PATH" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
<channel>
<title>Meetingnotes</title>
<description>Updates for Meetingnotes</description>
<language>en</language>
<item>
<title>Meetingnotes \${VERSION}</title>
<description>Latest version of Meetingnotes</description>
<pubDate>\${CURRENT_DATE}</pubDate>
<enclosure url="https://github.com/owengretzinger/meetingnotes/releases/download/v\${VERSION}/\${DMG_NAME}.dmg" length="\${DMG_SIZE}" type="application/octet-stream"/>
</item>
</channel>
</rss>
EOF

# Generate Sparkle appcast
echo "⚡ Generating Sparkle appcast..."
./bin/generate_appcast ./build/ \
--download-url-prefix "https://github.com/owengretzinger/meetingnotes/releases/download/v${VERSION}/" \
--output-path ./appcast.xml

echo "📝 Appcast generated: $APPCAST_PATH"
echo ""
echo "🎉 Release v$VERSION ready!"
echo "📋 Next steps:"
echo "   1. Create a new GitHub release with tag v$VERSION"
echo "   2. Upload the DMG file: $DMG_PATH"
echo "   3. Update the appcast.xml in the repository"
echo "   4. Test the update mechanism" 