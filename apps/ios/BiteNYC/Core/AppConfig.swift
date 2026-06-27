import Foundation

enum AppConfig {
    /// API base URL. Simulator uses localhost; physical devices use Info.plist
    /// (`BiteNYCAPIBaseURL`) so you can point at your Mac's LAN IP.
    static var apiBaseURL: URL {
        #if targetEnvironment(simulator)
        return URL(string: "http://127.0.0.1:4000")!
        #else
        if let raw = Bundle.main.object(forInfoDictionaryKey: "BiteNYCAPIBaseURL") as? String,
           !raw.isEmpty,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "http://127.0.0.1:4000")!
        #endif
    }

    /// Human-readable API origin for error messages.
    static var apiOriginLabel: String {
        apiBaseURL.host.map { host in
            let port = apiBaseURL.port.map { ":\($0)" } ?? ""
            return "\(host)\(port)"
        } ?? apiBaseURL.absoluteString
    }

    static var supabaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "BiteNYCSupabaseURL") as? String,
              !raw.isEmpty,
              let url = URL(string: raw) else { return nil }
        return url
    }

    static var supabaseAnonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "BiteNYCSupabaseAnonKey") as? String ?? ""
    }

    static var isSupabaseConfigured: Bool {
        supabaseURL != nil && !supabaseAnonKey.isEmpty
    }
}
