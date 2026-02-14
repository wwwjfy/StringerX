import Foundation
import CryptoKit

@Observable
@MainActor
class AccountService {
    enum LoginStatus {
        case loggedOut
        case loggingIn
        case loggedIn
    }

    var loginStatus: LoginStatus = .loggedOut
    var baseURL: String = ""

    private let apiClient = FeverAPIClient()
    private var savedCredentials: (url: String, token: String)?

    // Path to account.plist
    private var accountPlistPath: URL? {
        guard let appSupportDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        let stringerXDir = appSupportDir.appendingPathComponent("StringerX")
        return stringerXDir.appendingPathComponent("account.plist")
    }

    // MARK: - Auto Login

    func autoLogin(feedService: FeedService) async {
        guard let plistPath = accountPlistPath,
              FileManager.default.fileExists(atPath: plistPath.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: plistPath)
            let dict = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: String]

            guard let urlString = dict?["URL"],
                  let token = dict?["token"],
                  let url = URL(string: urlString) else {
                return
            }

            loginStatus = .loggingIn
            baseURL = urlString
            savedCredentials = (urlString, token)

            await apiClient.configure(baseURL: url, apiKey: token)

            let authResponse = try await apiClient.authenticate()
            if authResponse.isAuthenticated {
                loginStatus = .loggedIn
                await feedService.login(apiClient: apiClient)
            } else {
                loginStatus = .loggedOut
            }
        } catch {
            print("Auto-login failed: \(error.localizedDescription)")
            loginStatus = .loggedOut
        }
    }

    // MARK: - Login

    func login(url: String, password: String, feedService: FeedService) async throws {
        guard let baseURL = URL(string: url),
              (baseURL.scheme == "http" || baseURL.scheme == "https"),
              baseURL.host != nil else {
            throw AccountError.invalidURL
        }

        loginStatus = .loggingIn
        self.baseURL = url

        // Generate MD5 hash: MD5("stringer:<password>")
        let tokenInput = "stringer:\(password)"
        let token = md5Hash(string: tokenInput)

        await apiClient.configure(baseURL: baseURL, apiKey: token)

        do {
            let authResponse = try await apiClient.authenticate()
            guard authResponse.isAuthenticated else {
                loginStatus = .loggedOut
                throw AccountError.authenticationFailed
            }

            // Save credentials to plist
            try saveCredentials(url: url, token: token)
            savedCredentials = (url, token)
            loginStatus = .loggedIn

            // Start feed sync
            await feedService.login(apiClient: apiClient)
        } catch let error as FeverAPIError {
            loginStatus = .loggedOut
            throw AccountError.networkError(error.localizedDescription)
        } catch {
            loginStatus = .loggedOut
            throw error
        }
    }

    // MARK: - Logout

    func logout(feedService: FeedService) {
        loginStatus = .loggedOut
        baseURL = ""
        savedCredentials = nil

        // Delete account.plist
        if let plistPath = accountPlistPath {
            try? FileManager.default.removeItem(at: plistPath)
        }

        feedService.logout()
    }

    // MARK: - Helpers

    private func saveCredentials(url: String, token: String) throws {
        guard let plistPath = accountPlistPath else {
            throw AccountError.fileSystemError
        }

        let directory = plistPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let dict: [String: String] = ["URL": url, "token": token]
        let data = try PropertyListSerialization.data(
            fromPropertyList: dict,
            format: .xml,
            options: 0
        )
        try data.write(to: plistPath, options: .atomic)
    }

    private func md5Hash(string: String) -> String {
        let data = Data(string.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02X", $0) }.joined()
    }
}

// MARK: - Errors

enum AccountError: LocalizedError {
    case invalidURL
    case authenticationFailed
    case networkError(String)
    case fileSystemError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please enter a valid HTTP or HTTPS URL."
        case .authenticationFailed:
            return "Authentication failed. Please verify your password."
        case .networkError(let message):
            return "Network error: \(message)"
        case .fileSystemError:
            return "Failed to save account information."
        }
    }
}
