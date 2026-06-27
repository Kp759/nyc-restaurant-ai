import Foundation
import CryptoKit

enum SupabaseAuthError: LocalizedError {
    case notConfigured
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Sign-in is not configured yet. Add Supabase keys to Info.plist or continue as guest."
        case .invalidResponse: return "Unexpected response from the server."
        case let .server(message): return message
        }
    }
}

struct AuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var userId: String
    var email: String?
    var fullName: String?
}

/// Lightweight Supabase Auth client (REST) — no SDK required.
final class SupabaseAuthClient {
    private let url: URL?
    private let anonKey: String
    private let redirectURL = URL(string: "com.bitenyc.app://login-callback")!

    init() {
        url = AppConfig.supabaseURL
        anonKey = AppConfig.supabaseAnonKey
    }

    var isConfigured: Bool {
        url != nil && !anonKey.isEmpty
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        try await tokenRequest(body: ["email": email, "password": password], grantType: "password")
    }

    func signUp(email: String, password: String, fullName: String) async throws -> AuthSession {
        guard let url else { throw SupabaseAuthError.notConfigured }
        var request = URLRequest(url: url.appendingPathComponent("auth/v1/signup"))
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "data": ["full_name": fullName],
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response, data: data)
        return try decodeSession(data)
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        try await tokenRequest(body: [
            "provider": "apple",
            "id_token": idToken,
            "nonce": nonce,
        ], grantType: "id_token")
    }

    func googleOAuthURL() throws -> URL {
        guard let url else { throw SupabaseAuthError.notConfigured }
        var components = URLComponents(url: url.appendingPathComponent("auth/v1/authorize"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectURL.absoluteString),
        ]
        guard let authURL = components.url else { throw SupabaseAuthError.invalidResponse }
        return authURL
    }

    func session(fromOAuthCallback callbackURL: URL) throws -> AuthSession {
        guard let fragment = callbackURL.fragment else { throw SupabaseAuthError.invalidResponse }
        let params = Self.parseQuery(fragment)
        guard let access = params["access_token"], let refresh = params["refresh_token"] else {
            throw SupabaseAuthError.invalidResponse
        }
        return AuthSession(
            accessToken: access,
            refreshToken: refresh,
            userId: params["user_id"] ?? UUID().uuidString,
            email: params["email"],
            fullName: nil
        )
    }

    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(charset.randomElement()!)
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private

    private func tokenRequest(body: [String: String], grantType: String) async throws -> AuthSession {
        guard let url else { throw SupabaseAuthError.notConfigured }
        var request = URLRequest(url: URL(string: "\(url.absoluteString)/auth/v1/token?grant_type=\(grantType)")!)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response, data: data)
        return try decodeSession(data)
    }

    private func applyHeaders(_ request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    }

    private func validateHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw SupabaseAuthError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["msg"] as? String ?? json["error_description"] as? String ?? json["message"] as? String {
                throw SupabaseAuthError.server(msg)
            }
            throw SupabaseAuthError.server("Request failed (\(http.statusCode)).")
        }
    }

    private func decodeSession(_ data: Data) throws -> AuthSession {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = json["access_token"] as? String,
              let refresh = json["refresh_token"] as? String else {
            throw SupabaseAuthError.invalidResponse
        }
        let user = json["user"] as? [String: Any]
        let metadata = user?["user_metadata"] as? [String: Any]
        return AuthSession(
            accessToken: access,
            refreshToken: refresh,
            userId: user?["id"] as? String ?? UUID().uuidString,
            email: user?["email"] as? String,
            fullName: metadata?["full_name"] as? String
        )
    }

    private static func parseQuery(_ string: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in string.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                result[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
            }
        }
        return result
    }
}
