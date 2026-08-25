import Foundation

struct APIError: Error {
    let statusCode: Int
    let body: String?
}

/// The seam APIClient sends requests through. URLSession in the app, a stub in tests.
protocol HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

final class APIClient {
    let baseURL = URL(string: "https://bitelyapi-docker.onrender.com")!
    private let authStore: AuthStore
    private let transport: HTTPTransport

    init(authStore: AuthStore, transport: HTTPTransport = URLSession.shared) {
        self.authStore = authStore
        self.transport = transport
    }

    func request<T: Decodable>(path: String, method: String = "GET", query: [URLQueryItem] = [], body: Data? = nil, requiresAuth: Bool = false) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw URLError(.badURL) }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let token = authStore.accessToken
        if requiresAuth {
            guard let token else {
                throw APIError(statusCode: 401, body: "Missing access token")
            }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, resp) = try await transport.send(req)

        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func requestNoResponse(path: String, method: String, query: [URLQueryItem] = [], body: Data? = nil, requiresAuth: Bool = false) async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw URLError(.badURL) }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let token = authStore.accessToken
        if requiresAuth {
            guard let token else {
                throw APIError(statusCode: 401, body: "Missing access token")
            }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, resp) = try await transport.send(req)

        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }
}
