import Foundation

/// Rewrites proxied `/photo` URLs to the active API host so images load on
/// physical devices even when the DB still stores localhost or an old LAN IP.
enum MediaURLResolver {
    static func resolve(_ raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }

        if raw.hasPrefix("/") {
            return URL(string: raw, relativeTo: AppConfig.apiBaseURL)?.absoluteURL
        }

        guard let url = URL(string: raw) else { return nil }

        if isProxiedPhoto(url) {
            let query = url.query ?? URLComponents(url: url, resolvingAgainstBaseURL: false)?.query ?? ""
            let path = query.isEmpty ? "/photo" : "/photo?\(query)"
            return URL(string: path, relativeTo: AppConfig.apiBaseURL)?.absoluteURL
        }

        return url
    }

    private static func isProxiedPhoto(_ url: URL) -> Bool {
        if url.path == "/photo" || url.lastPathComponent == "photo" { return true }
        return url.query?.contains("name=places/") == true
    }
}
