import Foundation

enum AppConfig {
    /// API base URL. Read from Info.plist (`BiteNYCAPIBaseURL`) so it can be
    /// overridden per build configuration without code changes.
    static var apiBaseURL: URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "BiteNYCAPIBaseURL") as? String,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "http://localhost:4000")!
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
