import AuthenticationServices
import SwiftUI

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: AuthSession?
    @Published var isGuest = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseAuthClient()
    private let sessionKey = "bitenyc.auth.session"
    private let guestKey = "bitenyc.auth.guest"

    var canEnterApp: Bool { session != nil || isGuest }
    var isAuthenticated: Bool { session != nil }
    var usesRemoteAuth: Bool { client.isConfigured }

    init() {
        isGuest = UserDefaults.standard.bool(forKey: guestKey)
        restorePersistedSession()
    }

    func continueAsGuest() {
        isGuest = true
        UserDefaults.standard.set(true, forKey: guestKey)
        errorMessage = nil
    }

    func presentSignIn() {
        isGuest = false
        UserDefaults.standard.set(false, forKey: guestKey)
    }

    func signOut() {
        session = nil
        isGuest = false
        UserDefaults.standard.set(false, forKey: guestKey)
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func signIn(email: String, password: String) async {
        await runAuth {
            if client.isConfigured {
                return try await client.signIn(email: email, password: password)
            }
            return localSession(email: email, name: email.components(separatedBy: "@").first ?? "Foodie")
        }
    }

    func signUp(name: String, email: String, password: String) async {
        await runAuth {
            if client.isConfigured {
                return try await client.signUp(email: email, password: password, fullName: name)
            }
            return localSession(email: email, name: name)
        }
    }

    func signInWithApple(_ credential: ASAuthorizationAppleIDCredential, rawNonce: String) async {
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Apple Sign In did not return a token."
            return
        }

        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        await runAuth {
            if client.isConfigured {
                return try await client.signInWithApple(
                    idToken: idToken,
                    nonce: SupabaseAuthClient.sha256(rawNonce)
                )
            }
            let email = credential.email ?? "apple.user@bitenyc.app"
            return localSession(email: email, name: name.isEmpty ? "Apple User" : name)
        }
    }

    func signInWithGoogle() async {
        guard client.isConfigured else {
            await runAuth { localSession(email: "google.user@bitenyc.app", name: "Google User") }
            return
        }
        do {
            let authURL = try client.googleOAuthURL()
            await MainActor.run { isLoading = true }
            let callbackURL = try await OAuthPresenter.shared.start(url: authURL, callbackScheme: "com.bitenyc.app")
            let newSession = try client.session(fromOAuthCallback: callbackURL)
            applySession(newSession)
        } catch {
            if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func handleOpenURL(_ url: URL) {
        guard url.scheme == "com.bitenyc.app", url.host == "login-callback" else { return }
        Task {
            do {
                let newSession = try client.session(fromOAuthCallback: url)
                applySession(newSession)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func applySessionToAccount(_ account: AccountStore) {
        guard let session else { return }
        let name = session.fullName ?? session.email?.components(separatedBy: "@").first ?? "Food Explorer"
        account.profile.name = name
        if account.profile.tagline == "NYC food explorer" || account.profile.tagline.isEmpty {
            account.profile.tagline = "NYC food explorer"
        }
    }

    // MARK: - Private

    private func runAuth(_ work: () async throws -> AuthSession) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            applySession(try await work())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applySession(_ newSession: AuthSession) {
        session = newSession
        isGuest = false
        UserDefaults.standard.set(false, forKey: guestKey)
        if let data = try? JSONEncoder().encode(newSession) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func localSession(email: String, name: String) -> AuthSession {
        AuthSession(
            accessToken: "local-\(UUID().uuidString)",
            refreshToken: "local",
            userId: UUID().uuidString,
            email: email,
            fullName: name
        )
    }

    private func restorePersistedSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let saved = try? JSONDecoder().decode(AuthSession.self, from: data) else { return }
        session = saved
    }
}

/// Presents Google OAuth in an in-app browser sheet.
final class OAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresenter()
    private var activeSession: ASWebAuthenticationSession?

    func start(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { [weak self] url, error in
                self?.activeSession = nil
                if let error { continuation.resume(throwing: error); return }
                guard let url else {
                    continuation.resume(throwing: SupabaseAuthError.invalidResponse)
                    return
                }
                continuation.resume(returning: url)
            }
            activeSession = session
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
