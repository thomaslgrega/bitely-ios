//
//  AuthService.swift
//  Bitely
//
//  Created by Thomas Grega on 1/28/26.
//

import Foundation

@Observable
@MainActor
final class AuthService {
    private let api: APIClient
    private let authStore: AuthStore

    init(api: APIClient, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    func register(email: String, password: String) async throws {
        let payload = try JSONEncoder().encode(RegisterRequest(email: email, password: password))
        let res: AuthResponse = try await api.request(path: "auth/register", method: "POST", body: payload, requiresAuth: false)
        authStore.setSession(token: res.accessToken, user: res.user)
    }

    func login(email: String, password: String) async throws {
        let payload = try JSONEncoder().encode(LoginRequest(email: email, password: password))
        let res: AuthResponse = try await api.request(path: "auth/login", method: "POST", body: payload, requiresAuth: false)
        authStore.setSession(token: res.accessToken, user: res.user)
    }

    func bootstrap() async {
        guard authStore.isAuthenticated else { return }

        do {
            let me: User = try await api.request(path: "me", requiresAuth: true)
            authStore.user = me
        } catch {
            authStore.signOut()
        }
    }
}

private struct RegisterRequest: Encodable {
    let email: String
    let password: String
}

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}
