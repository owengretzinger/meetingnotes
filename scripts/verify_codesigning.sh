#!/bin/bash

# Verify Code Signing Setup for Meetingnotes
# This script checks if your Apple Developer credentials are properly configured

set -e

echo "🔍 Code Signing Verification"
echo "============================"
echo ""

# Check environment variables
echo "📋 Environment Variables:"

if [ -n "$DEVELOPER_ID" ]; then
    echo "   ✅ DEVELOPER_ID: $DEVELOPER_ID"
else
    echo "   ❌ DEVELOPER_ID: Not set (REQUIRED)"
fi

if [ -n "$APPLE_ID" ]; then
    echo "   ✅ APPLE_ID: $APPLE_ID"
else
    echo "   ❌ APPLE_ID: Not set (REQUIRED for notarization)"
fi

if [ -n "$TEAM_ID" ]; then
    echo "   ✅ TEAM_ID: $TEAM_ID"
else
    echo "   ❌ TEAM_ID: Not set (REQUIRED)"
fi

if [ -n "$APP_PASSWORD" ]; then
    echo "   ✅ APP_PASSWORD: $APP_PASSWORD"
else
    echo "   ❌ APP_PASSWORD: Not set (REQUIRED for notarization)"
fi

echo ""

# Check certificates
echo "🔍 Available Certificates:"
DEVELOPER_ID_CERTS=$(security find-identity -v -p codesigning | grep "Developer ID Application" || true)
if [ -n "$DEVELOPER_ID_CERTS" ]; then
    echo "   ✅ Developer ID Application certificates found:"
    echo "$DEVELOPER_ID_CERTS" | sed 's/^/      /'
else
    echo "   ❌ No Developer ID Application certificates found"
fi

echo ""

# Validate certificate matches expected
if [ -n "$DEVELOPER_ID_CERTS" ]; then
    echo "   ✅ Developer ID Application certificates are available"
else
    echo "   ❌ No Developer ID Application certificates found"
    echo "      Install your certificate from Apple Developer portal"
fi

echo ""

# Check notarytool
echo "🔍 Notarization Tools:"
if command -v xcrun &> /dev/null; then
    if xcrun --find notarytool &> /dev/null; then
        echo "   ✅ notarytool available"
    else
        echo "   ❌ notarytool not found (requires Xcode 13+)"
    fi
else
    echo "   ❌ xcrun not available"
fi

echo ""

# Check entitlements file
echo "🔍 Entitlements File:"
if [ -f "meetingnotes/meetingnotes.entitlements" ]; then
    echo "   ✅ meetingnotes.entitlements found"
else
    echo "   ❌ meetingnotes.entitlements not found"
fi

echo ""

# Overall status
echo "📊 Overall Status:"
CERT_OK=$(echo "$DEVELOPER_ID_CERTS" | grep -q "Developer ID Application" && echo "true" || echo "false")
CREDS_OK=$([ -n "$DEVELOPER_ID" ] && [ -n "$APPLE_ID" ] && [ -n "$TEAM_ID" ] && [ -n "$APP_PASSWORD" ] && echo "true" || echo "false")

if [ "$CERT_OK" = "true" ] && [ "$CREDS_OK" = "true" ]; then
    echo "   🎉 Ready for production builds with notarization!"
elif [ "$CERT_OK" = "true" ]; then
    echo "   ⚠️  Certificate installed, but missing environment variables"
else
    echo "   ❌ Missing certificate or environment variables"
fi

echo ""
echo "🚀 Next Steps:"
if [ "$CERT_OK" = "false" ]; then
    echo "   1. Install your Developer ID certificate in Keychain"
    echo "   2. Run: ./scripts/setup_codesigning.sh"
    echo "   3. Set up your .env file with credentials"
elif [ "$CREDS_OK" = "false" ]; then
    echo "   1. Run: ./scripts/setup_codesigning.sh"
    echo "   2. Create and configure your .env file"
    echo "   3. Test: source .env && ./scripts/verify_codesigning.sh"
else
    echo "   1. Run: source .env && ./scripts/build_release.sh"
    echo "   2. Test the resulting DMG on another Mac"
    echo "   3. Upload to GitHub releases"
fi

echo ""
echo "💡 Quick setup with .env file:"
echo "   1. Copy .env.template to .env: cp .env.template .env"
echo "   2. Edit .env with your Apple ID and app-specific password"
echo "   3. Load and verify: source .env && ./scripts/verify_codesigning.sh" 