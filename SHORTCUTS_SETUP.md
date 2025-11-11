# iOS Shortcuts Setup Guide

This guide explains how to set up the iOS Shortcut to send notes from the app to Claude.

## Overview

The app includes a "Send to Claude" feature that integrates with iOS Shortcuts to send note content to the Claude AI assistant. This feature is only available on iOS devices.

## Prerequisites

- iOS device with iOS 13 or later
- Shortcuts app installed (pre-installed on iOS 13+)
- Claude app or access to Claude via web/API

## Creating the "SendToClaude" Shortcut

### Option 1: For Short Notes (Recommended for Simple Setup)

1. Open the **Shortcuts** app on your iOS device
2. Tap the **+** button to create a new shortcut
3. Add the following actions:
   - **Get text from input** (receives the note text from the app)
   - **Open URL**: Configure to open Claude with the text (depends on Claude's URL scheme)
   - OR **Share**: Share the text to the Claude app

4. Name the shortcut exactly: **SendToClaude** (case-sensitive)
5. Save the shortcut

### Option 2: For Long Notes (Clipboard Approach)

1. Open the **Shortcuts** app on your iOS device
2. Tap the **+** button to create a new shortcut
3. Add the following actions:
   - **Get Clipboard**
   - **Set variable** to "NoteText"
   - **Open URL**: Configure to open Claude with the clipboard text
   - OR **Share**: Share the clipboard content to the Claude app

4. Name the shortcut exactly: **SendToClaude** (case-sensitive)
5. Save the shortcut

### Example Shortcut Actions

```
Action 1: Get text from input
Action 2: Text → Set variable "NoteContent"
Action 3: Show "NoteContent" (or send to Claude)
```

## How It Works

### Short Text (<2000 characters)
- The app sends the note content directly via URL scheme
- Format: `shortcuts://run-shortcut?name=SendToClaude&input=text&text=<encoded_content>`

### Long Text (>2000 characters)
- The app copies the note to clipboard
- Launches the shortcut without text parameter
- The shortcut reads from clipboard
- Format: `shortcuts://run-shortcut?name=SendToClaude`

## Using the Feature

1. Open any note in the editor
2. Tap the **Send** icon (paper plane) in the top right corner
3. The iOS Shortcuts app will open and run your shortcut
4. The note content will be sent to Claude according to your shortcut configuration

## Troubleshooting

### Error: "Shortcut 'SendToClaude' not found"
- Make sure you've created the shortcut in the Shortcuts app
- Verify the shortcut name is exactly **SendToClaude** (case-sensitive)
- Check that the shortcut is not disabled

### Error: "Could not launch shortcut"
- Ensure the Shortcuts app is installed
- Grant necessary permissions to the Shortcuts app
- Try restarting your device

### Error: "This feature is only available on iOS"
- This feature only works on iOS devices
- Android users can use the standard share functionality (coming in Phase 8)

### Note content not appearing in Claude
- Check your shortcut configuration
- Make sure the shortcut correctly handles the input text
- For long notes, ensure the shortcut reads from clipboard

## Customizing the Shortcut Name

If you want to use a different shortcut name:

1. The default name is **SendToClaude**
2. To use a custom name, you'll need to modify the app settings (feature to be added in Phase 9)
3. Currently, the shortcut name is hardcoded in the app

## Advanced Configuration

### Integrating with Claude API

You can configure your shortcut to:
1. Format the note content as needed
2. Add context or instructions to the text
3. Send directly to Claude API endpoint
4. Store responses back to the app (requires additional setup)

### Example Shortcut with API Integration

```
Action 1: Get text from input → NoteText
Action 2: Text: "Please help me with this note: [NoteText]"
Action 3: Get contents of URL: https://api.anthropic.com/v1/messages
  - Method: POST
  - Headers: Add your API key
  - Body: JSON with your prompt and NoteText
Action 4: Show result
```

## Security Considerations

- Note content is sent via iOS Shortcuts, which runs locally on your device
- Be cautious about sending sensitive information
- If using Claude API, ensure your API key is stored securely
- The clipboard approach temporarily stores note content in clipboard

## Future Enhancements

Planned improvements for future versions:
- Custom shortcut name configuration
- Direct Claude API integration
- Response handling (receive Claude's response back in the app)
- Share extension for easier sharing
- Siri integration for voice commands

## Support

For issues or questions:
- Check the app documentation
- Review iOS Shortcuts documentation: https://support.apple.com/guide/shortcuts/
- Ensure you're running the latest version of iOS and the app

---

**Note:** The exact configuration of the shortcut depends on how you want to interact with Claude (web URL, API, app deep link, etc.). Adjust the shortcut actions based on your preferred method.
