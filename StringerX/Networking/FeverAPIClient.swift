import Foundation

actor FeverAPIClient {
    private var baseURL: URL?
    private var apiKey: String?
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Configuration

    func configure(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    func isConfigured() -> Bool {
        return baseURL != nil && apiKey != nil
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(_ path: String, additionalParams: [String: String] = [:]) async throws -> T {
        guard let baseURL = baseURL, let apiKey = apiKey else {
            throw FeverAPIError.notConfigured
        }

        // Construct URL - Fever has quirky format like "fever/?feeds&api_key=..."
        // Build the full URL string first, then parse
        var urlString = baseURL.absoluteString
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        urlString += path

        guard var components = URLComponents(string: urlString) else {
            throw FeverAPIError.invalidURL
        }

        // Add API key and additional parameters as query items
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        for (key, value) in additionalParams {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        // Fever's URL format has parameters after '?' in the path, so we need to append to existing query items
        if components.queryItems == nil {
            components.queryItems = queryItems
        } else {
            components.queryItems?.append(contentsOf: queryItems)
        }

        guard let url = components.url else {
            throw FeverAPIError.invalidURL
        }

        // Make request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw FeverAPIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeverAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FeverAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Decode JSON
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw FeverAPIError.decodingError(error)
        }
    }

    // MARK: - API Endpoints

    func authenticate() async throws -> AuthResponse {
        return try await request("fever/?")
    }

    func fetchFeeds() async throws -> FeedsResponse {
        return try await request("fever/?feeds")
    }

    func fetchFavicons() async throws -> FaviconsResponse {
        return try await request("fever/?favicons")
    }

    func fetchUnreadItemIds() async throws -> UnreadItemIdsResponse {
        return try await request("fever/?unread_item_ids")
    }

    func fetchSavedItemIds() async throws -> SavedItemIdsResponse {
        return try await request("fever/?saved_item_ids")
    }

    func fetchItems(withIds ids: [Int]) async throws -> ItemsResponse {
        let idsString = ids.map { String($0) }.joined(separator: ",")
        return try await request("fever/?items&with_ids=\(idsString)")
    }

    // Batch fetch items in groups of 50 using TaskGroup for concurrent requests
    func fetchItemsBatch(itemIds: [Int]) async throws -> [Item] {
        let batchSize = 50
        let batches = stride(from: 0, to: itemIds.count, by: batchSize).map {
            Array(itemIds[$0..<min($0 + batchSize, itemIds.count)])
        }

        return try await withThrowingTaskGroup(of: [Item].self) { group in
            for batch in batches {
                group.addTask {
                    let response: ItemsResponse = try await self.fetchItems(withIds: batch)
                    return response.items
                }
            }

            var allItems: [Item] = []
            for try await items in group {
                allItems.append(contentsOf: items)
            }
            return allItems
        }
    }

    func markItemAsRead(itemId: Int) async throws {
        _ = try await request("fever/?mark=item&as=read&id=\(itemId)") as AuthResponse
    }

    func markItemAsUnread(itemId: Int) async throws {
        _ = try await request("fever/?mark=item&as=unread&id=\(itemId)") as AuthResponse
    }

    func markItemAsSaved(itemId: Int) async throws {
        _ = try await request("fever/?mark=item&as=saved&id=\(itemId)") as AuthResponse
    }

    func markItemAsUnsaved(itemId: Int) async throws {
        _ = try await request("fever/?mark=item&as=unsaved&id=\(itemId)") as AuthResponse
    }

    func markAllAsRead(beforeTimestamp: Int) async throws {
        _ = try await request("fever/?mark=group&as=read&id=0&before=\(beforeTimestamp)") as AuthResponse
    }
}

// MARK: - Errors

enum FeverAPIError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case networkError(String)
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API client is not configured with base URL and API key"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let message):
            return "Network error: \(message)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
