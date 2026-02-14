import Foundation
import AppKit

struct Feed: Codable, Identifiable, @unchecked Sendable {
    let id: Int
    let title: String
    let faviconId: Int

    // Transient property not from API - set after fetching favicons
    var faviconImage: NSImage?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case faviconId = "favicon_id"
    }

    // Custom decoder to initialize without faviconImage
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        faviconId = try container.decode(Int.self, forKey: .faviconId)
        faviconImage = nil
    }

    // Custom encoder
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(faviconId, forKey: .faviconId)
    }

    // Memberwise initializer for testing
    init(id: Int, title: String, faviconId: Int, faviconImage: NSImage? = nil) {
        self.id = id
        self.title = title
        self.faviconId = faviconId
        self.faviconImage = faviconImage
    }
}
