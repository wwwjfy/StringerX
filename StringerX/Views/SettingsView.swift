import SwiftUI

struct SettingsView: View {
    @Environment(FeedService.self) private var feedService
    @Environment(AccountService.self) private var accountService

    @State private var urlInput: String = ""
    @State private var passwordInput: String = ""
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var accountServiceBindable = accountService

        Form {
            Section {
                TextField("Server URL:", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(accountService.loginStatus != .loggedOut)
                    .onAppear {
                        urlInput = accountService.baseURL
                    }

                SecureField("Password:", text: $passwordInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(accountService.loginStatus != .loggedOut)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button(buttonTitle) {
                        handleButtonPress()
                    }
                    .disabled(accountService.loginStatus == .loggingIn)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 200)
        .padding()
    }

    private var buttonTitle: String {
        switch accountService.loginStatus {
        case .loggedOut:
            return "Log in"
        case .loggingIn:
            return "Logging in..."
        case .loggedIn:
            return "Log out"
        }
    }

    private func handleButtonPress() {
        if accountService.loginStatus == .loggedIn {
            // Logout
            accountService.logout(feedService: feedService)
            passwordInput = ""
            errorMessage = nil
        } else {
            // Login
            guard !urlInput.isEmpty && !passwordInput.isEmpty else {
                errorMessage = "Please enter both URL and password"
                return
            }

            errorMessage = nil

            Task {
                do {
                    try await accountService.login(
                        url: urlInput,
                        password: passwordInput,
                        feedService: feedService
                    )
                    passwordInput = ""
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
