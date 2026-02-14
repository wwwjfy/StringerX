import Foundation

struct Item: Codable, Identifiable {
    let id: Int
    let feedId: Int
    let createdOnTime: Int
    var isRead: Bool
    let title: String
    let html: String
    let author: String?
    let url: String
    var isSaved: Bool

    // Local state not from API
    var localRead: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case feedId = "feed_id"
        case createdOnTime = "created_on_time"
        case isRead = "is_read"
        case title
        case html
        case author
        case url
        case isSaved = "is_saved"
    }

    // Custom decoder to handle Fever API's integer booleans (0/1)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        feedId = try container.decode(Int.self, forKey: .feedId)
        createdOnTime = try container.decode(Int.self, forKey: .createdOnTime)
        title = try container.decode(String.self, forKey: .title)
        html = try container.decode(String.self, forKey: .html)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        url = try container.decode(String.self, forKey: .url)

        // Fever API returns 0/1 instead of true/false
        let isReadInt = try container.decode(Int.self, forKey: .isRead)
        isRead = isReadInt != 0

        let isSavedInt = try container.decode(Int.self, forKey: .isSaved)
        isSaved = isSavedInt != 0

        localRead = false
    }

    // Custom encoder to convert back to integer booleans
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(feedId, forKey: .feedId)
        try container.encode(createdOnTime, forKey: .createdOnTime)
        try container.encode(isRead ? 1 : 0, forKey: .isRead)
        try container.encode(title, forKey: .title)
        try container.encode(html, forKey: .html)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(url, forKey: .url)
        try container.encode(isSaved ? 1 : 0, forKey: .isSaved)
    }
}
