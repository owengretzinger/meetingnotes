<div align="center">
  <!-- REMOVE THIS IF YOU DON'T HAVE A LOGO -->
    <img src="https://github.com/user-attachments/assets/de32601b-4b15-4cfd-b839-71b135d33f61" alt="Logo" width="80" height="80">

<h3 align="center">Meetingnotes</h3>

  <p align="center">
    The Free, Open-Source AI Notetaker for Busy Engineers
    <br />
     <a href="https://github.com/owengretzinger/meetingnotes/releases/latest/download/Meetingnotes.dmg">Download for MacOS 14+</a>
  </p>
</div>

<!-- REMOVE THIS IF YOU DON'T HAVE A DEMO -->
<!-- TIP: You can alternatively directly upload a video up to 100MB by dropping it in while editing the README on GitHub. This displays a video player directly on GitHub instead of making it so that you have to click an image/link -->
https://github.com/user-attachments/assets/cadd4504-e9d9-4ccd-874d-41d8a84f4c9d

<!--
## Table of Contents

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#key-features">Key Features</a></li>
      </ul>
    </li>
    <li><a href="#architecture">Architecture</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## About The Project

Brief description of the project.

### Key Features

- **Feature 1:** ...
- **Feature 2:** ...
- ...

## Architecture

![Architecture Diagram](https://github.com/user-attachments/assets/75adc7aa-7719-4c4f-a9bb-3ba847e12e9f)

(Insert the different technologies used in the project here — could split this into frontend, backend, etc)

(Don't explain what well-known technologies like React are)

## Getting Started

### Prerequisites

- Requirement 1
- Requirement 2
  ```sh
  installation command (if applicable)
  ```

### Installation

Instructions for cloning the repo, installing packages, configuring environment variables, etc:

1. Step 1
   ```sh
   command
   ```
2. Step 2
   ```sh
   command
   ```
3. ...

## Acknowledgments

- This README was created using [gitreadme.dev](https://gitreadme.dev) — an AI tool that looks at your entire codebase to instantly generate high-quality README files.
- (Only include unique things that you are sure should be specifically acknowledged. Don't include libraries or tools like React, Next.js, etc. Don't include services like Vercel, OpenAI, Google Cloud, JetBrains, etc. Stay on the safe side since more can be added later. Do not hallucinate.)

-->

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
- Different note templates
- Integrate with Posthog for anonymous analytics (installs, opens, meetings created)
- Onboarding screen to enable settings and set API key

Todo:

- check for funds / validity of openai api key
- add padding to text inputs
- add confirmation when clicking the copy button

Later:

- Cool recording indicator (dancing bars)
- Connecting to your Google calendar
- AI chat for asking questions about a meeting
- Ability to use different models
- Ability to use different STT providers
- Integrations for email, Slack, Notion, etc.

## Local Development

Open the project in Xcode. Command+R to build it and run it.

## Releasing a New Version

Follow these steps to create a new release with auto-updates:

### Prerequisites

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

   - Go to [GitHub Releases](https://github.com/owengretzinger/meetingnotes/releases)
   - Click "Create a new release"
   - Tag: `v1.0.1` (match the version number)
   - Title: `Meetingnotes v1.0.1`
   - Upload the DMG and zip files from `releases/` folder
   - Generate release notes

4. **Update appcast:**

   ```bash
   git add appcast.xml
   git commit -m "Update appcast for v1.0.1"
   git push
   ```
