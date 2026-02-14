import SwiftUI

struct ItemRowView: View {
    let item: Item
    let feedName: String
    let faviconImage: NSImage?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Favicon (20x20)
            if let faviconImage = faviconImage {
                Image(nsImage: faviconImage)
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(item.localRead ? .secondary : .primary)

                // Source and preview
                HStack(spacing: 8) {
                    Text(feedName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let preview = extractPreview(from: item.html) {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(preview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Saved indicator (red circle)
            if item.isSaved {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
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
