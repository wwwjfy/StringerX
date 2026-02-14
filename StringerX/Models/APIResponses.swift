import Foundation

// MARK: - Auth Response
struct AuthResponse: Codable, Sendable {
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

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        auth = try container.decode(Int.self, forKey: .auth)
        apiVersion = try container.decodeIfPresent(Int.self, forKey: .apiVersion)
        lastRefreshedOnTime = try container.decodeIfPresent(Int.self, forKey: .lastRefreshedOnTime)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(auth, forKey: .auth)
        try container.encodeIfPresent(apiVersion, forKey: .apiVersion)
        try container.encodeIfPresent(lastRefreshedOnTime, forKey: .lastRefreshedOnTime)
    }
}

// MARK: - Feeds Response
struct FeedsResponse: Codable, Sendable {
    let feeds: [Feed]
    let feedGroups: [FeedGroup]?

    enum CodingKeys: String, CodingKey {
        case feeds
        case feedGroups = "feed_groups"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        feeds = try container.decode([Feed].self, forKey: .feeds)
        feedGroups = try container.decodeIfPresent([FeedGroup].self, forKey: .feedGroups)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(feeds, forKey: .feeds)
        try container.encodeIfPresent(feedGroups, forKey: .feedGroups)
    }
}

struct FeedGroup: Codable, Sendable {
    let id: Int
    let title: String
}

// MARK: - Favicons Response
struct FaviconsResponse: Codable, Sendable {
    let favicons: [Favicon]

    enum CodingKeys: String, CodingKey {
        case favicons
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        favicons = try container.decode([Favicon].self, forKey: .favicons)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(favicons, forKey: .favicons)
    }
}

// MARK: - Items Response
struct ItemsResponse: Codable, Sendable {
    let items: [Item]
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case items
        case total = "total_items"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([Item].self, forKey: .items)
        total = try container.decodeIfPresent(Int.self, forKey: .total)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(total, forKey: .total)
    }
}

// MARK: - Unread Item IDs Response
struct UnreadItemIdsResponse: Codable, Sendable {
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

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unreadItemIds = try container.decode(String.self, forKey: .unreadItemIds)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(unreadItemIds, forKey: .unreadItemIds)
    }
}

// MARK: - Saved Item IDs Response
struct SavedItemIdsResponse: Codable, Sendable {
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

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        savedItemIds = try container.decode(String.self, forKey: .savedItemIds)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(savedItemIds, forKey: .savedItemIds)
    }
}
