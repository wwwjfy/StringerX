import Foundation

// MARK: - Auth Response
struct AuthResponse: Codable {
    let auth: Int
    let apiVersion: Int?
    let lastRefreshedOnTime: Int?

    enum CodingKeys: String, CodingKey {
        case auth
        case apiVersion = "api_version"
        case lastRefreshedOnTime = "last_refreshed_on_time"
    }

    var isAuthenticated: Bool {
        return auth != 0
    }
}

// MARK: - Feeds Response
struct FeedsResponse: Codable {
    let feeds: [Feed]
    let feedGroups: [FeedGroup]?

    enum CodingKeys: String, CodingKey {
        case feeds
        case feedGroups = "feed_groups"
    }
}

struct FeedGroup: Codable {
    let id: Int
    let title: String
}

// MARK: - Favicons Response
struct FaviconsResponse: Codable {
    let favicons: [Favicon]
}

// MARK: - Items Response
struct ItemsResponse: Codable {
    let items: [Item]
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case items
        case total = "total_items"
    }
}

// MARK: - Unread Item IDs Response
struct UnreadItemIdsResponse: Codable {
    let unreadItemIds: String

    enum CodingKeys: String, CodingKey {
        case unreadItemIds = "unread_item_ids"
    }

    var itemIds: [Int] {
        guard !unreadItemIds.isEmpty else {
            return []
        }
        return unreadItemIds.components(separatedBy: ",").compactMap { Int($0) }
    }
}

// MARK: - Saved Item IDs Response
struct SavedItemIdsResponse: Codable {
    let savedItemIds: String

    enum CodingKeys: String, CodingKey {
        case savedItemIds = "saved_item_ids"
    }

    var itemIds: [Int] {
        guard !savedItemIds.isEmpty else {
            return []
        }
        return savedItemIds.components(separatedBy: ",").compactMap { Int($0) }
    }
}
