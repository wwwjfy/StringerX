import SwiftUI

struct ArticleView: View {
    let item: Item
    @Environment(\.colorScheme) var colorScheme
    @State private var hoveredURL: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Article WebView
            ArticleWebView(
                htmlContent: formattedHTML,
                hoveredURL: $hoveredURL
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
}
