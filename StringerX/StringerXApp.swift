import SwiftUI

@main
struct StringerXApp: App {
    @State private var feedService = FeedService()
    @State private var accountService = AccountService()

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environment(feedService)
                .environment(accountService)
                .onAppear {
                    Task {
                        await accountService.autoLogin(feedService: feedService)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                // Remove default "New" menu item
            }

            // Custom keyboard shortcuts
            CommandMenu("Navigate") {
                Button("Next Item") {
                    feedService.selectNext()
                }
                .keyboardShortcut("j", modifiers: [])

                Button("Previous Item") {
                    feedService.selectPrevious()
                }
                .keyboardShortcut("k", modifiers: [])

                Button("Toggle Article") {
                    feedService.toggleArticle()
                }
                .keyboardShortcut("o", modifiers: [])

                Button("Go to Top") {
                    feedService.goToTop()
                }
                .keyboardShortcut("g", modifiers: [])
            }

            CommandMenu("Actions") {
                Button("Open in Browser") {
                    feedService.openInBrowser()
                }
                .keyboardShortcut("v", modifiers: [])

                Button("Toggle Saved") {
                    feedService.toggleSaved()
                }
                .keyboardShortcut("s", modifiers: [])

                Button("Mark All as Read") {
                    feedService.markAllAsRead()
                }
                .keyboardShortcut("a", modifiers: [.shift])
            }
        }

        Settings {
            SettingsView()
                .environment(feedService)
                .environment(accountService)
        }
    }
}
