# File Listing for Xcode Project

When creating the Xcode project manually, add all these files to the target:

## Main Entry Point
- `StringerX/StringerXApp.swift` - Main @main App struct

## Models (4 files)
- `StringerX/Models/Item.swift`
- `StringerX/Models/Feed.swift`
- `StringerX/Models/Favicon.swift`
- `StringerX/Models/APIResponses.swift`

## Networking (1 file)
- `StringerX/Networking/FeverAPIClient.swift`

## Services (2 files)
- `StringerX/Services/FeedService.swift`
- `StringerX/Services/AccountService.swift`

## Views (6 files)
- `StringerX/Views/MainContentView.swift`
- `StringerX/Views/FeedListView.swift`
- `StringerX/Views/ItemRowView.swift`
- `StringerX/Views/ArticleWebView.swift`
- `StringerX/Views/ArticleView.swift`
- `StringerX/Views/SettingsView.swift`

## Utilities (2 files)
- `StringerX/Utilities/HTMLFormatter.swift`
- `StringerX/Utilities/ViewExtensions.swift`

## Resources
- `StringerX/Resources/Assets.xcassets/` - App icons
- `StringerX/Info.plist` - App configuration

## Total: 16 Swift files + 1 plist + 1 asset catalog

## Required Framework Imports

The following frameworks are used:
- `Foundation` - All files
- `SwiftUI` - All view files, main app
- `AppKit` - Feed.swift, Favicon.swift, FeedService.swift, ItemRowView.swift
- `WebKit` - ArticleWebView.swift
- `CryptoKit` - AccountService.swift (for MD5 hashing)

## External Dependencies

Add via Swift Package Manager:
- **SwiftSoup** (https://github.com/scinfu/SwiftSoup.git) version 2.7.0+
  - Used in: HTMLFormatter.swift
