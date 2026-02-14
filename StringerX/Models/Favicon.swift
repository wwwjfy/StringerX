import Foundation
import AppKit

struct Favicon: Codable, Identifiable {
    let id: Int
    let data: String

    // Computed property to convert data URI to NSImage
    var image: NSImage? {
        // Favicon data comes as data URI: "data:image/png;base64,..."
        guard data.hasPrefix("data:") else {
            return nil
        }

        // Extract the base64 part after the comma
        let components = data.components(separatedBy: ",")
        guard components.count == 2,
              let imageData = Data(base64Encoded: components[1]) else {
            return nil
        }

        return NSImage(data: imageData)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case data
    }
}
