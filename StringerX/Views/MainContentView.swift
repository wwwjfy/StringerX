import SwiftUI

struct MainContentView: View {
    @Environment(FeedService.self) private var feedService

    var body: some View {
        ZStack {
            // Feed list (always visible)
            FeedListView()

            // Article overlay (conditionally visible)
            if feedService.isArticleOpen,
               let currentItem = feedService.currentItem {
                ArticleView(item: currentItem)
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
