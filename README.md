# EveryDay - iOS Journal & Chat App

A personal journaling app with AI chat integration, built with SwiftUI.

## Features

- 📝 **Journal Entries**: Write daily entries with photos, videos, and location
- 🤖 **AI Chat**: Chat with AI therapist presets for reflection and guidance
- 🔒 **Face ID Security**: Secure your journal with Face ID authentication
- 📸 **Media Support**: Add photos and videos to your entries
- 🎤 **Speech Recognition**: Transcribe audio and video content
- 📍 **Location Tracking**: Automatically tag entries with your location
- 🔔 **Notifications**: Set reminders to journal regularly
- 🎨 **Customizable**: Dark/light themes and adjustable font sizes

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/cgmelamed/EveryDay.git
cd EveryDay
```

### 2. Configure API Key
1. Copy the `Config.plist` file to include your API key:
   ```bash
   cp EveryDay/Config.plist EveryDay/Config.plist.local
   ```
2. Open `EveryDay/Config.plist` and replace `YOUR_ANTHROPIC_API_KEY_HERE` with your actual Anthropic API key
3. The `Config.plist` file is gitignored to keep your API key secure

### 3. Open in Xcode
1. Open `EveryDay.xcodeproj` in Xcode
2. Select your development team in the project settings
3. Build and run on your device or simulator

### 4. Permissions
The app requires the following permissions:
- Camera (for photos/videos)
- Photo Library (for selecting media)
- Microphone (for audio recording)
- Location Services (for entry tagging)
- Face ID/Touch ID (for security)
- Notifications (for reminders)

## Requirements

- iOS 17.2+
- Xcode 15+
- Anthropic API key

## Security

- API keys are stored in `Config.plist` which is excluded from git
- All sensitive data is stored locally on device
- Face ID/Touch ID provides additional security layer

## Development

The app follows MVVM architecture with SwiftUI views and combines modern iOS frameworks like:
- SwiftUI for UI
- Core Data for persistence
- AVFoundation for media
- Core Location for location services
- Speech framework for transcription
- JournalingSuggestions for iOS 17.2+ features

## License

Private project - All rights reserved.