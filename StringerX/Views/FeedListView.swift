import SwiftUI

struct FeedListView: View {
    @Environment(FeedService.self) private var feedService

    var body: some View {
        @Bindable var feedServiceBindable = feedService

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
    }
}
