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
}
