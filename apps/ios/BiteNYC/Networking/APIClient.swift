import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case http(Int, String)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL."
        case let .http(code, msg): return "Server error (\(code)): \(msg)"
        case let .decoding(msg): return "Could not read the response: \(msg)"
        case let .transport(msg): return msg
        }
    }
}

/// Parameters for the Explore list endpoint (`GET /restaurants`).
struct RestaurantQuery {
    var borough: String?
    var neighborhood: String?
    var maxPriceTier: Int?
    var vibe: [String] = []
    var occasion: [String] = []
    var cuisine: [String] = []
    var openNow: Bool = false
    var reservationAvailable: Bool = false
    var limit: Int = 30
    var offset: Int = 0
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: Restaurants

    func restaurants(_ query: RestaurantQuery = .init()) async throws -> [Restaurant] {
        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(query.limit)),
            .init(name: "offset", value: String(query.offset)),
        ]
        if let b = query.borough { items.append(.init(name: "borough", value: b)) }
        if let n = query.neighborhood { items.append(.init(name: "neighborhood", value: n)) }
        if let p = query.maxPriceTier { items.append(.init(name: "max_price_tier", value: String(p))) }
        if !query.vibe.isEmpty { items.append(.init(name: "vibe", value: query.vibe.joined(separator: ","))) }
        if !query.occasion.isEmpty { items.append(.init(name: "occasion", value: query.occasion.joined(separator: ","))) }
        if !query.cuisine.isEmpty { items.append(.init(name: "cuisine", value: query.cuisine.joined(separator: ","))) }
        if query.openNow { items.append(.init(name: "open_now", value: "true")) }
        if query.reservationAvailable { items.append(.init(name: "reservation_available", value: "true")) }

        let response: RestaurantListResponse = try await get("/restaurants", query: items)
        return response.restaurants
    }

    func restaurant(slug: String) async throws -> Restaurant {
        try await get("/restaurants/\(slug)")
    }

    // MARK: Search + Chat

    func search(query: String, filters: SearchFilters? = nil, limit: Int = 5) async throws -> SearchResponse {
        struct Body: Encodable {
            let query: String
            let filters: SearchFilters?
            let limit: Int
        }
        return try await post("/search", body: Body(query: query, filters: filters, limit: limit))
    }

    func chat(message: String, history: [ChatTurn] = []) async throws -> ChatResponse {
        struct Body: Encodable {
            let message: String
            let history: [ChatTurn]
        }
        return try await post("/chat", body: Body(message: message, history: history))
    }

    // MARK: Metadata

    func filters() async throws -> FiltersResponse { try await get("/filters") }

    func neighborhoods() async throws -> [Neighborhood] {
        let response: NeighborhoodsResponse = try await get("/neighborhoods")
        return response.neighborhoods
    }

    // MARK: Moderation

    func report(targetType: String, targetId: String, reason: String, details: String?) async throws {
        struct Body: Encodable {
            let targetType: String
            let targetId: String
            let reason: String
            let details: String?
        }
        let _: EmptyResponse = try await post(
            "/reports",
            body: Body(targetType: targetType, targetId: targetId, reason: reason, details: details)
        )
    }

    // MARK: - Core request helpers

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await send(request)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(Self.connectionHelp(from: error))
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport("No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw APIError.http(http.statusCode, message)
        }
        if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T {
            return empty
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private static func connectionHelp(from error: Error) -> String {
        let ns = error as NSError
        guard ns.domain == NSURLErrorDomain else { return error.localizedDescription }

        #if targetEnvironment(simulator)
        return """
        Can't reach the BiteNYC API at \(AppConfig.apiOriginLabel). \
        Run `pnpm dev:api` on your Mac — the simulator uses http://127.0.0.1:4000.
        """
        #else
        return """
        Can't reach the BiteNYC API at \(AppConfig.apiOriginLabel). \
        Run `pnpm dev:api` on your Mac and set BiteNYCAPIBaseURL in Info.plist to your Mac's LAN IP (e.g. http://192.168.1.20:4000).
        """
        #endif
    }
}

struct ChatTurn: Codable, Hashable {
    var role: String   // "user" | "assistant"
    var content: String
}

struct EmptyResponse: Decodable {}
