Introducing Meetingnotes: the free, open-source AI notetaker for busy engineers.

- 100% free (bring your own OpenAI API key)
- 100% privacy (all data stored on device)
- 100% open source (please contribute)

## Features

Implemented:

- Recording mic & system audio
- Live transcript
- Ability to also write down additional notes
- AI generated enhanced notes
- Copy functionality
- Meeting deletion functionality
- Meeting search functionality
- Abilty to edit system prompt
- Use your own API key
- Auto updates
- Text formatting

Todo:

- Different note templates

Later:

- Cool recording indicator (dancing bars)
- Connecting to your Google calendar
- AI chat for asking questions about a meeting
- Ability to use different models
- Ability to use different STT providers
- Integrations for email, Slack, Notion, etc.

## Local Development

Open the project in Xcode.

For faster development builds, ensure `ONLY_ACTIVE_ARCH = YES` is set in your Debug configuration (this is already set by default). This builds only for your current architecture, speeding up compilation.

For distribution builds that need to support both Intel and Apple Silicon Macs, the release process automatically uses `ONLY_ACTIVE_ARCH = NO` to create universal binaries.

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
