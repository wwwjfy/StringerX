import Foundation
import AppKit

@Observable
@MainActor
class FeedService {
    // State
    var items: [Int: Item] = [:]
    var itemIds: [Int] = []
    var feeds: [Int: Feed] = [:]
    var selectedItemId: Int?
    var isArticleOpen: Bool = false

    private var apiClient: FeverAPIClient?
    private var syncTimer: Timer?
    private var syncCounter: Int = 0
    private var lastItemCreatedOn: Int = 0

    // MARK: - Login / Logout

    func login(apiClient: FeverAPIClient) async {
        self.apiClient = apiClient

        // Fetch feeds -> favicons -> sync items -> start timer
        await fetchFeeds()
        await fetchFavicons()
        await syncUnreadItems()
        startSyncTimer()
    }

    func logout() {
        stopSyncTimer()
        apiClient = nil
        items = [:]
        itemIds = []
        feeds = [:]
        selectedItemId = nil
        isArticleOpen = false
        lastItemCreatedOn = 0
        syncCounter = 0
        updateDockBadge()
    }

    // MARK: - Fetching Data

    private func fetchFeeds() async {
        guard let apiClient = apiClient else { return }

        do {
            let response = try await apiClient.fetchFeeds()
            for feed in response.feeds {
                var updatedFeed = feed
                // Preserve existing favicon image if we already have it
                if let existingFeed = feeds[feed.id] {
                    updatedFeed.faviconImage = existingFeed.faviconImage
                }
                feeds[feed.id] = updatedFeed
            }
        } catch {
            // Silently fail
        }
    }

    private func fetchFavicons() async {
        guard let apiClient = apiClient else { return }

        do {
            let response = try await apiClient.fetchFavicons()
            var faviconMap: [Int: NSImage] = [:]

            for favicon in response.favicons {
                if let image = favicon.image {
                    faviconMap[favicon.id] = image
                }
            }

            // Update feeds with favicon images
            for (feedId, var feed) in feeds {
                if let image = faviconMap[feed.faviconId] {
                    feed.faviconImage = image
                    feeds[feedId] = feed
                }
            }
        } catch {
            // Silently fail
        }
    }

    private func syncUnreadItems() async {
        guard let apiClient = apiClient else { return }

        do {
            // Fetch both unread and saved item IDs
            async let unreadResponse = apiClient.fetchUnreadItemIds()
            async let savedResponse = apiClient.fetchSavedItemIds()

            let unreadIds = try await unreadResponse.itemIds
            let savedIds = try await savedResponse.itemIds

            // Combine and deduplicate
            let allIds = Array(Set(unreadIds + savedIds))

            if allIds.isEmpty {
                updateItems([])
                return
            }

            // Batch fetch items (50 at a time, concurrent)
            let fetchedItems = try await apiClient.fetchItemsBatch(itemIds: allIds)

            // Sort by created_on_time DESC (newest first)
            let sortedItems = fetchedItems.sorted { $0.createdOnTime > $1.createdOnTime }

            updateItems(sortedItems)
        } catch {
            // Silently fail
        }

        // Increment counter and re-fetch feeds every 10th cycle (50 minutes)
        syncCounter += 1
        if syncCounter % 10 == 0 {
            syncCounter = 0
            await fetchFeeds()
            await fetchFavicons()
        }
    }

    private func updateItems(_ newItems: [Item]) {
        let oldItems = items
        let currentId = selectedItemId

        // Clear current items
        items = [:]
        itemIds = []

        // Update items, preserving localRead state
        for var item in newItems {
            if let oldItem = oldItems[item.id] {
                item.localRead = oldItem.localRead || item.isRead
            } else {
                item.localRead = item.isRead
            }
            items[item.id] = item
            itemIds.append(item.id)
        }

        // Update last item timestamp for mark all read
        if let firstItem = newItems.first {
            lastItemCreatedOn = firstItem.createdOnTime
        }

        // Preserve selection if possible
        if let currentId = currentId, items[currentId] != nil {
            selectedItemId = currentId
        } else if selectedItemId != nil {
            // Current selection is gone, clear it
            selectedItemId = nil
        }

        updateDockBadge()
    }

    // MARK: - Timer

    private func startSyncTimer() {
        stopSyncTimer()

        // 5-minute intervals with 30-second tolerance
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncUnreadItems()
            }
        }
        syncTimer?.tolerance = 30
    }

    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Item Operations

    func selectNext() {
        guard !itemIds.isEmpty else { return }

        if let currentId = selectedItemId,
           let currentIndex = itemIds.firstIndex(of: currentId) {
            let nextIndex = currentIndex + 1
            if nextIndex < itemIds.count {
                selectedItemId = itemIds[nextIndex]
            }
        } else {
            // No selection, select first item
            selectedItemId = itemIds.first
        }
    }

    func selectPrevious() {
        guard !itemIds.isEmpty else { return }

        if let currentId = selectedItemId,
           let currentIndex = itemIds.firstIndex(of: currentId) {
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                selectedItemId = itemIds[prevIndex]
            }
        } else {
            // No selection, select first item
            selectedItemId = itemIds.first
        }
    }

    func goToTop() {
        guard !itemIds.isEmpty else { return }
        selectedItemId = itemIds.first
    }

    func toggleArticle() {
        isArticleOpen.toggle()
    }

    func openArticle() {
        guard selectedItemId != nil else { return }
        isArticleOpen = true
    }

    func closeArticle() {
        isArticleOpen = false
    }

    func openInBrowser() {
        guard let itemId = selectedItemId,
              let item = items[itemId],
              let url = URL(string: item.url) else {
            return
        }

        // Open in Safari in background without switching focus
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false  // Don't bring Safari to front

        NSWorkspace.shared.open(
            [url],
            withApplicationAt: URL(fileURLWithPath: "/Applications/Safari.app"),
            configuration: configuration
        )
    }

    func toggleSaved() {
        guard let itemId = selectedItemId,
              var item = items[itemId],
              let apiClient = apiClient else {
            return
        }

        let wasSaved = item.isSaved
        item.isSaved = !wasSaved
        items[itemId] = item

        Task {
            do {
                if item.isSaved {
                    try await apiClient.markItemAsSaved(itemId: itemId)
                } else {
                    try await apiClient.markItemAsUnsaved(itemId: itemId)
                }
            } catch {
                // Rollback on failure
                var revertedItem = item
                revertedItem.isSaved = wasSaved
                items[itemId] = revertedItem
            }
        }
    }

    func markAllAsRead() {
        guard let apiClient = apiClient else { return }

        let currentId = selectedItemId

        Task {
            do {
                // Mark all as read on server (using last item timestamp + 1)
                try await apiClient.markAllAsRead(beforeTimestamp: lastItemCreatedOn + 1)

                // Filter to keep only saved items locally
                let savedItems = items.values.filter { $0.isSaved }
                let sortedSavedItems = savedItems.sorted { $0.createdOnTime > $1.createdOnTime }

                updateItems(Array(sortedSavedItems))

                // Try to preserve selection
                if let currentId = currentId, items[currentId] != nil {
                    selectedItemId = currentId
                } else {
                    selectedItemId = nil
                }
            } catch {
                // Silently fail
            }
        }
    }

    func markItemAsRead(itemId: Int) {
        guard var item = items[itemId],
              let apiClient = apiClient else {
            return
        }

        guard !item.isRead else { return }

        item.isRead = true
        item.localRead = true
        items[itemId] = item

        Task {
            do {
                try await apiClient.markItemAsRead(itemId: itemId)
            } catch {
                // Silently fail
            }
        }
    }

    // MARK: - Helpers

    func getItem(at index: Int) -> Item? {
        guard index >= 0 && index < itemIds.count else { return nil }
        let itemId = itemIds[index]
        return items[itemId]
    }

    func getFeedName(for item: Item) -> String {
        return feeds[item.feedId]?.title ?? ""
    }

    func getFaviconImage(for item: Item) -> NSImage? {
        return feeds[item.feedId]?.faviconImage
    }

    var currentItem: Item? {
        guard let selectedId = selectedItemId else { return nil }
        return items[selectedId]
    }

    private func updateDockBadge() {
        let unreadCount = items.values.filter { !$0.localRead }.count
        if unreadCount > 0 {
            NSApp.dockTile.badgeLabel = "\(unreadCount)"
        } else {
            NSApp.dockTile.badgeLabel = nil
        }
    }
}
