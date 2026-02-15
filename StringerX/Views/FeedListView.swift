import SwiftUI

struct FeedListView: View {
    @Environment(FeedService.self) private var feedService

    var body: some View {
        @Bindable var feedServiceBindable = feedService

        ScrollViewReader { proxy in
            List(feedService.itemIds, id: \.self, selection: $feedServiceBindable.selectedItemId) { itemId in
                if let item = feedService.items[itemId] {
                    ItemRowView(
                        item: item,
                        feedName: feedService.getFeedName(for: item),
                        faviconImage: feedService.getFaviconImage(for: item)
                    )
                    .tag(itemId)
                }
            }
            .listStyle(.inset)
            .alternatingRowBackgrounds()
            .onKeyPress("o", action: {
                feedService.toggleArticle()
                return .handled
            })
            .onKeyPress("g", action: {
                feedService.goToTop()
                return .handled
            })
            .onKeyPress("j", action: {
                feedService.selectNext()
                return .handled
            })
            .onKeyPress("k", action: {
                feedService.selectPrevious()
                return .handled
            })
            .onKeyPress("v", action: {
                feedService.openInBrowser()
                return .handled
            })
            .onKeyPress("s", action: {
                feedService.toggleSaved()
                return .handled
            })
            .onKeyPress("A", action: {  // Shift+A (capital A)
                feedService.markAllAsRead()
                return .handled
            })
            .onChange(of: feedService.hasNewPosts) { _, hasNew in
                if hasNew, let firstItemId = feedService.itemIds.first {
                    withAnimation {
                        proxy.scrollTo(firstItemId, anchor: .top)
                    }
                    feedService.hasNewPosts = false
                }
            }
            .onChange(of: feedService.selectedItemId) { _, newSelectedId in
                if let newSelectedId = newSelectedId {
                    proxy.scrollTo(newSelectedId)
                }
            }
        }
    }
}
