#!/bin/bash

# Version Update Script for Meetingnotes
# Usage: ./update_version.sh [major|minor|patch|build] [custom_version]

set -e

PROJECT_FILE="Meetingnotes.xcodeproj/project.pbxproj"
CURRENT_MARKETING_VERSION=$(grep -m1 "MARKETING_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/\1/')
CURRENT_BUILD_VERSION=$(grep -m1 "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/\1/')

if [ -z "$CURRENT_MARKETING_VERSION" ] || [ -z "$CURRENT_BUILD_VERSION" ]; then
    echo "❌ Could not determine current version from project file"
    echo "   Make sure $PROJECT_FILE exists and contains MARKETING_VERSION and CURRENT_PROJECT_VERSION"
    exit 1
fi

echo "📋 Current Version Info:"
echo "   Marketing Version: $CURRENT_MARKETING_VERSION"
echo "   Build Version: $CURRENT_BUILD_VERSION"
echo ""

# Function to increment version
increment_version() {
    local version=$1
    local type=$2
    
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]:-0}
    local minor=${VERSION_PARTS[1]:-0}
    local patch=${VERSION_PARTS[2]:-0}
    
    case $type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            echo "❌ Invalid increment type: $type"
            exit 1
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Function to update version in project file
update_project_version() {
    local new_marketing_version=$1
    local new_build_version=$2
    
    # Update marketing version
    sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $new_marketing_version;/g" "$PROJECT_FILE"
    
    # Update build version
    sed -i '' "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $new_build_version;/g" "$PROJECT_FILE"
    
    echo "✅ Updated project file:"
    echo "   Marketing Version: $CURRENT_MARKETING_VERSION → $new_marketing_version"
    echo "   Build Version: $CURRENT_BUILD_VERSION → $new_build_version"
}

# Main logic
case $1 in
    "major"|"minor"|"patch")
        NEW_MARKETING_VERSION=$(increment_version "$CURRENT_MARKETING_VERSION" "$1")
        NEW_BUILD_VERSION=$((CURRENT_BUILD_VERSION + 1))
        update_project_version "$NEW_MARKETING_VERSION" "$NEW_BUILD_VERSION"
        ;;
    "build")
        NEW_BUILD_VERSION=$((CURRENT_BUILD_VERSION + 1))
        update_project_version "$CURRENT_MARKETING_VERSION" "$NEW_BUILD_VERSION"
        ;;
    "custom")
        if [ -z "$2" ]; then
            echo "❌ Please provide a custom version number"
            echo "Usage: ./update_version.sh custom 1.2.0"
            exit 1
        fi
        NEW_BUILD_VERSION=$((CURRENT_BUILD_VERSION + 1))
        update_project_version "$2" "$NEW_BUILD_VERSION"
        ;;
    *)
        echo "🔢 Version Update Script"
        echo ""
        echo "Usage:"
        echo "   ./update_version.sh major     # 1.0 → 2.0"
        echo "   ./update_version.sh minor     # 1.0 → 1.1"
        echo "   ./update_version.sh patch     # 1.0 → 1.0.1"
        echo "   ./update_version.sh build     # Keep version, increment build"
        echo "   ./update_version.sh custom 1.2.0  # Set specific version"
        echo ""
        echo "Current version: $CURRENT_MARKETING_VERSION (build $CURRENT_BUILD_VERSION)"
        exit 0
        ;;
esac

echo ""
echo "🎯 Next steps:"
echo "   1. Test the app to make sure everything works"
echo "   2. Run ./build_release.sh to create a release"
echo "   3. The new version will be: $(grep -m1 "MARKETING_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/\1/')" 