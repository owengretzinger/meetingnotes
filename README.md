Introducing Notetaker, an open source Granola alternative for on-device AI meeting notes:

- 100% free (bring your own Deepgram & OpenAI API keys)
- 100% data privacy (data stored on device)
- 100% open source (please contribute)

## Features

Implemented:

- Recording mic & system audio
- Live transcript using Deepgram
- Ability to also write down additional notes
- AI generated enhanced notes
- Copy functionality
- Meeting deletion functionality
- Meeting search functionality
- Abilty to edit system prompt
- Use your own API key

Todo:

- Add license
- Auto updates
- Auto migration of meeting files (incase of format changes)

Later:

- Cool recording indicator (dancing bars)
- Connecting to your Google calendar
- Different note templates
- AI chat for asking questions about a meeting
- Ability to use different models
- Ability to use different STT providers
- Integrations for email, Slack, Notion, etc.

## Local Development

Open the project in Xcode

## Releasing a New Version

Follow these steps to create a new release with auto-updates:

### Prerequisites

<!-- - Apple Developer Account with valid certificates -->

- Homebrew packages: `brew install create-dmg sparkle`
- Make scripts executable: `chmod +x scripts/update_version.sh scripts/build_release.sh`

### Release Process

1. **Update the version number:**

   ```bash
   # For bug fixes (1.0 → 1.0.1):
   ./scripts/update_version.sh patch

   # For new features (1.0 → 1.1):
   ./scripts/update_version.sh minor

   # For major changes (1.0 → 2.0):
   ./scripts/update_version.sh major

   # For custom version:
   ./scripts/update_version.sh custom 1.2.0
   ```

2. **Build the release:**

   ```bash
   ./scripts/build_release.sh
   ```

   This will:

   - Clean build the app in Release mode
   - Create a signed DMG file
   - Generate the appcast.xml for auto-updates

3. **Create GitHub Release:**

   - Go to [GitHub Releases](https://github.com/owengretzinger/notetaker/releases)
   - Click "Create a new release"
   - Tag: `v1.0.1` (match the version number)
   - Title: `Notetaker v1.0.1`
   - Upload the DMG from `releases/` folder
   - Write release notes describing changes

4. **Update appcast:**

   ```bash
   git add appcast.xml
   git commit -m "Update appcast for v1.0.1"
   git push
   ```
