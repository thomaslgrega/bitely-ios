//
//  APIClient.swift
//  WhatWeEating
//
//  Created by Thomas Grega on 1/28/26.
//

import Foundation

struct APIError: Error {
    let statusCode: Int
    let body: String?
}

final class APIClient {
    let baseURL = URL(string: "http://localhost:8080")!
    private let authStore: AuthStore

    init(authStore: AuthStore) {
        self.authStore = authStore
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

        let (data, resp) = try await URLSession.shared.data(for: req)

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

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }
}
