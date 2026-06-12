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

            CommandMenu("Navigate") {
                Button("Next Item") {
                    feedService.selectNext()
                }

                Button("Previous Item") {
                    feedService.selectPrevious()
                }

                Button("Toggle Article") {
                    feedService.toggleArticle()
                }

                Button("Go to Top") {
                    feedService.goToTop()
                }
            }

            CommandMenu("Actions") {
                Button("Open in Browser") {
                    feedService.openInBrowser()
                }

                Button("Toggle Saved") {
                    feedService.toggleSaved()
                }

                Button("Mark All as Read") {
                    feedService.markAllAsRead()
                }
            }
        }

        Settings {
            SettingsView()
                .environment(feedService)
                .environment(accountService)
        }
    }
}
