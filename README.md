# EchoRead 📚 -> 🎧

EchoRead is an intelligent PDF reader and learning companion that allows you to attach voice notes to specific text selections in your documents.

## Features

- **PDF Library**: Import and organize your PDF documents.
- **Grid View**: Beautiful grid layout with thumbnail previews.
- **Collections**: Group related PDFs into named collections (folders).
- **Voice Annotations**: 
    - Select text in any PDF to record a voice note.
    - Voice notes are saved and linked to the text.
    - **Playback**: Play, pause, and resume voice notes.
    - **Navigation**: Clicking a voice note sidebar item automatically scrolls the PDF to the relevant text.
    - **Progress Tracking**: Visual progress bar for playing notes.

## Platforms

- **macOS** (v14+)
- **iPadOS** (iOS 17+)

## How to Run

### Using Xcode

1.  Open the project folder in **Xcode**.
2.  Wait for Swift Package Dependencies to resolve.

### Running on iPad
**Note**: "iPadOS" is included under **iOS** in Xcode.

1.  Click the version/device selector in the top toolbar (usually shows "My Mac").
2.  Select **iOS Simulators** (or **iOS**).
3.  Choose an iPad simulator (e.g., **iPad Pro (12.9-inch)**).
4.  Press **Cmd + R** to run.

### Running on Mac
1.  Select **My Mac** in the device selector.
2.  Press **Cmd + R** to run.

## Exporting for Sharing (macOS)

To execute the app without Xcode:

1.  Open Terminal in the project folder.
2.  Run the bundle script:
    ```bash
    chmod +x bundle_app.sh
    ./bundle_app.sh
    ```
3.  The `EchoRead.app` will be created in the project folder. You can zip and share this.
