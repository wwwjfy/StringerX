# StringerX Swift Rewrite

A modern Swift rewrite of StringerX, a native macOS client for [Stringer](https://github.com/stringer-rss/stringer) RSS feed reader.

## Overview

This is a complete rewrite from Objective-C to Swift with the following modern technologies:

- **SwiftUI** for the UI layer
- **async/await** for networking
- **Swift Package Manager** for dependencies
- **Observation framework** (`@Observable`) for state management
- **Swift actors** for thread-safe networking
- **macOS 15+** deployment target

## Dependencies

The only external dependency is:
- **SwiftSoup** (2.7.0+) - For HTML parsing and formatting

## Project Structure

```
StringerX/
├── StringerXApp.swift              # Main app entry point with keyboard shortcuts
├── Models/
│   ├── Item.swift                  # Feed item model with custom Codable for Fever API
│   ├── Feed.swift                  # Feed model
│   ├── Favicon.swift               # Favicon with data URI to NSImage conversion
│   └── APIResponses.swift          # Wrapper types for API responses
├── Networking/
│   └── FeverAPIClient.swift        # Swift actor for async API calls
├── Services/
│   ├── FeedService.swift           # @Observable main service for feeds and items
│   └── AccountService.swift        # Credential storage and authentication
├── Views/
│   ├── MainContentView.swift       # ZStack: feed list + article overlay
│   ├── FeedListView.swift          # SwiftUI List of items
│   ├── ItemRowView.swift           # Individual item row
│   ├── ArticleWebView.swift        # NSViewRepresentable WKWebView
│   ├── ArticleView.swift           # Article container with URL hover
│   └── SettingsView.swift          # Login/logout preferences
├── Utilities/
│   ├── HTMLFormatter.swift         # SwiftSoup-based article formatting
│   └── ViewExtensions.swift        # SwiftUI extensions
└── Resources/
    └── Assets.xcassets/            # App icons (copied from original)
```

## Building the Project

### Option 1: Create Xcode Project Manually

1. Open Xcode and create a new **macOS App** project
2. Choose **SwiftUI** for the interface
3. Choose **Swift** for the language
4. Set the product name to **StringerX**
5. Set the bundle identifier to **net.wwwjfy.StringerX**
6. Set deployment target to **macOS 15.0** (or latest available)

7. **Add the source files:**
   - Delete the default `ContentView.swift` and auto-generated files
   - Add all files from the `StringerX/` directory to the project
   - Ensure `Info.plist` is referenced in build settings
   - Ensure `Assets.xcassets` is added to the project

8. **Add SwiftSoup dependency:**
   - Go to **File > Add Package Dependencies**
   - Enter: `https://github.com/scinfu/SwiftSoup.git`
   - Select version 2.7.0 or later
   - Add to the StringerX target

9. **Configure build settings:**
   - Set **Product Bundle Identifier** to `net.wwwjfy.StringerX`
   - Verify **App Category** is set (e.g., Lifestyle)
   - Enable **Hardened Runtime** if needed for distribution

10. **Build and run** (Cmd+R)

### Option 2: Use Swift Package Manager (Command Line)

The included `Package.swift` file allows building as an SPM package, but note that this won't produce a proper macOS .app bundle:

```bash
cd StringerX-Swift
swift build
swift run
```

For a proper macOS application, use Option 1 (Xcode project).

## Features

### Keyboard Shortcuts

All keyboard shortcuts work without modifiers (except where noted):

| Key | Action |
|-----|--------|
| `j` | Next item |
| `k` | Previous item |
| `o` | Toggle article view |
| `v` | Open in browser (Safari) |
| `s` | Toggle saved |
| `g` | Go to top |
| `⇧A` | Mark all as read |

### Core Features

- **Auto-login** - Automatically logs in on launch if credentials are saved
- **5-minute sync** - Polls for new items every 5 minutes
- **Feed refresh** - Re-fetches feeds every 50 minutes (10th sync cycle)
- **Batch fetching** - Fetches items in batches of 50 concurrently
- **Saved items** - Toggle saved status with visual indicator (red dot)
- **Mark all read** - Marks all items as read, keeps saved items visible
- **Dark mode** - Article rendering adapts to system appearance
- **Dock badge** - Shows unread count
- **Link handling** - All article links open in Safari without switching focus
- **URL hover** - Shows link URLs on mouseover

## Migration from Objective-C Version

The Swift version uses the **same credential storage location** as the Objective-C version:

```
~/Library/Application Support/StringerX/account.plist
```

This means if you have the old version installed and logged in, the new version will automatically detect your credentials and log you in.

## API Compatibility

Uses the Fever API with the following endpoints:

- `fever/?` - Authentication
- `fever/?feeds` - Fetch feeds
- `fever/?favicons` - Fetch favicons
- `fever/?unread_item_ids` - Fetch unread item IDs
- `fever/?saved_item_ids` - Fetch saved item IDs
- `fever/?items&with_ids=...` - Fetch items by ID
- `fever/?mark=item&as=...` - Mark items read/unread/saved/unsaved
- `fever/?mark=group&as=read...` - Mark all items as read

## Verification Checklist

After building, verify the following:

- [ ] Open Settings (Cmd+,), enter Stringer server URL + password
- [ ] Verify login succeeds and preferences window closes
- [ ] Verify feed list populates with items, favicons, and feed names
- [ ] Test `j`/`k` navigation between items
- [ ] Test `o` to open article view
- [ ] Test `v` to open article in Safari
- [ ] Test `s` to toggle saved (red dot indicator appears/disappears)
- [ ] Test `⇧A` to mark all as read
- [ ] Verify dock badge shows correct unread count
- [ ] Wait 5 minutes and verify auto-sync updates the list
- [ ] Toggle system dark mode and verify article re-renders with dark CSS
- [ ] Test logout and re-login flow
- [ ] If old Objective-C version is installed, verify credential migration works

## Known Differences from Original

1. **SwiftUI instead of XIB files** - Modern declarative UI
2. **No MASPreferences** - Uses native SwiftUI Settings scene
3. **No AFNetworking** - Uses URLSession with async/await
4. **No YYModel** - Uses native Codable
5. **SwiftSoup instead of HTMLKit** - More actively maintained HTML parser
6. **@Observable instead of NSNotificationCenter** - Automatic SwiftUI updates
7. **Actor for API client** - Thread-safe by design

## Troubleshooting

### "Cannot find type 'FeedService' in scope"

Make sure all files are added to the Xcode target. Check the **Target Membership** in the File Inspector.

### "Insecure HTTP loads are blocked"

Verify that `NSAllowsArbitraryLoads` is set to `true` in Info.plist under `NSAppTransportSecurity`.

### SwiftSoup not found

Make sure the SwiftSoup package dependency is added via Xcode's package manager (File > Add Package Dependencies).

### Keyboard shortcuts not working

Ensure the shortcuts are defined in the `StringerXApp.swift` file under `.commands`. Modifier-less shortcuts are intentionally suppressed when text fields have focus.

## License

Copyright © 2013 Tony Wang. All rights reserved.

(Match the license from the original Objective-C version)
