import Foundation
import AppKit

struct Favicon: Codable, Identifiable, Sendable {
    let id: Int
    let data: String

    // Computed property to convert data URI to NSImage
    var image: NSImage? {
        // Fever API returns favicon data WITHOUT "data:" prefix
        // Format: "image/png;base64,iVBORw0KGgo..."
        // We need to prepend "data:" to make it a valid data URI

        let dataURI = data.hasPrefix("data:") ? data : "data:\(data)"

        // Extract the base64 part after the comma
        let components = dataURI.components(separatedBy: ",")
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
