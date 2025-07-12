#!/bin/bash
# Version Update Script for Meetingnotes

set -e

# Configuration
PROJECT_FILE="meetingnotes.xcodeproj/project.pbxproj"

# Check if version is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.1"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format (basic check)
if [[ ! $NEW_VERSION =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "❌ Invalid version format. Use format like 1.0.1"
    exit 1
fi

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Project file not found: $PROJECT_FILE"
    exit 1
fi

echo "🔄 Updating version to $NEW_VERSION..."

# Update MARKETING_VERSION in project file
sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $NEW_VERSION/" "$PROJECT_FILE"

# Verify the change
if grep -q "MARKETING_VERSION = $NEW_VERSION" "$PROJECT_FILE"; then
    echo "✅ Version updated to $NEW_VERSION"
else
    echo "❌ Failed to update version"
    exit 1
fi

echo "🎉 Version update complete!"
echo "   Don't forget to commit and push the changes" 