import SwiftUI

struct ItemRowView: View {
    let item: Item
    let feedName: String
    let faviconImage: NSImage?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Favicon with saved indicator below
            VStack(spacing: 2) {
                if let faviconImage = faviconImage {
                    Image(nsImage: faviconImage)
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }

                // Saved indicator (red dot) below icon
                if item.isSaved {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                } else {
                    // Invisible spacer to maintain consistent height
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title - 1 line
                Text(item.title)
                    .font(.title3)
                    .lineLimit(1)
                    .foregroundColor(item.localRead ? .secondary : .primary)
                    .foregroundStyle(item.localRead ? .secondary : .primary)

                // Feed name - 1 line
                Text(feedName)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Preview - 2 lines
                if let preview = extractPreview(from: item.html) {
                    Text(preview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // Extract plain text preview from HTML
    private func extractPreview(from html: String) -> String? {
        // Simple HTML tag stripping for preview
        let stripped = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !stripped.isEmpty else { return nil }
        return String(stripped.prefix(100))
    }
}
