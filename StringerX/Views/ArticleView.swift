import SwiftUI

struct ArticleView: View {
    let item: Item
    @Environment(\.colorScheme) var colorScheme
    @Environment(FeedService.self) private var feedService
    @State private var hoveredURL: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Article WebView
            ArticleWebView(
                htmlContent: formattedHTML,
                baseURL: articleOrigin,
                hoveredURL: $hoveredURL,
                onShortcut: handleShortcut,
                onEscape: { feedService.closeArticle() }
            )
            .focusable()  // Make the webview focusable

            // URL hover bar at bottom-left
            if let url = hoveredURL {
                Text(url)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                    .cornerRadius(4)
                    .padding(8)
            }
        }
    }

    private var formattedHTML: String {
        HTMLFormatter.formatArticle(item: item, isDarkMode: colorScheme == .dark)
    }

    private var articleOrigin: URL? {
        guard let url = URL(string: item.url),
              let scheme = url.scheme,
              let host = url.host else {
            return nil
        }
        return URL(string: "\(scheme)://\(host)/")
    }

    private func handleShortcut(_ c: Character) {
        switch c {
        case "j": feedService.selectNext()
        case "k": feedService.selectPrevious()
        case "o": feedService.toggleArticle()
        case "g": feedService.goToTop()
        case "v": feedService.openInBrowser()
        case "s": feedService.toggleSaved()
        case "A": feedService.markAllAsRead()
        default: break
        }
    }
}
