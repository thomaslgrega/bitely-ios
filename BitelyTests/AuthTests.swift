//
//  AuthTests.swift
//  BitelyTests
//

import Foundation
import Testing
@testable import Bitely

@Suite("AuthStore")
struct AuthStoreTests {
    private let tokenKey = "access_token"

    @Test("starts signed out when no token is stored")
    func startsSignedOut() {
        let store = AuthStore(defaults: makeIsolatedDefaults())

        #expect(store.accessToken == nil)
        #expect(store.isAuthenticated == false)
    }

    @Test("restores a stored token on init")
    func restoresStoredToken() {
        let defaults = makeIsolatedDefaults()
        defaults.set("stored-token", forKey: tokenKey)

        let store = AuthStore(defaults: defaults)

        #expect(store.accessToken == "stored-token")
        #expect(store.isAuthenticated)
    }

    @Test("treats an empty stored token as signed out")
    func treatsEmptyTokenAsSignedOut() {
        let defaults = makeIsolatedDefaults()
        defaults.set("", forKey: tokenKey)

        let store = AuthStore(defaults: defaults)

        #expect(store.accessToken == nil)
        #expect(store.isAuthenticated == false)
    }

    @Test("setSession holds the user in memory and persists only the token")
    func setSessionPersistsToken() {
        let defaults = makeIsolatedDefaults()
        let store = AuthStore(defaults: defaults)

        store.setSession(
            token: "new-token",
            user: User(id: "u1", email: "cook@example.com", firstName: "Ada", lastName: nil)
        )

        #expect(store.isAuthenticated)
        #expect(store.user?.id == "u1")
        #expect(defaults.string(forKey: tokenKey) == "new-token")
    }

    @Test("signOut clears the session in memory and on disk")
    func signOutClearsEverything() {
        let defaults = makeIsolatedDefaults()
        let store = AuthStore(defaults: defaults)
        store.setSession(token: "t", user: User(id: "u1", email: nil, firstName: nil, lastName: nil))

        store.signOut()

        #expect(store.accessToken == nil)
        #expect(store.user == nil)
        #expect(store.isAuthenticated == false)
        #expect(defaults.string(forKey: tokenKey) == nil)
    }

    @Test("a signed-out store leaves no token behind for the next launch")
    func signOutSurvivesRelaunch() {
        let defaults = makeIsolatedDefaults()
        AuthStore(defaults: defaults).setSession(
            token: "t",
            user: User(id: "u1", email: nil, firstName: nil, lastName: nil)
        )

        AuthStore(defaults: defaults).signOut()

        #expect(AuthStore(defaults: defaults).isAuthenticated == false)
    }
}

@Suite("AuthService")
@MainActor
struct AuthServiceTests {
    private let authPayload = #"""
    {
      "access_token": "jwt-token",
      "user": { "id": "u1", "email": "cook@example.com", "first_name": "Ada", "last_name": null }
    }
    """#

    private func makeService(transport: StubTransport) -> (AuthService, AuthStore) {
        let store = AuthStore(defaults: makeIsolatedDefaults())
        let service = AuthService(api: APIClient(authStore: store, transport: transport), authStore: store)
        return (service, store)
    }

    @Test("login posts the credentials to auth/login")
    func loginPostsCredentials() async throws {
        let transport = StubTransport.json(authPayload)
        let (service, _) = makeService(transport: transport)

        try await service.login(email: "cook@example.com", password: "hunter2")

        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/login")

        let body = try #require(request.httpBody)
        let sent = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(sent["email"] as? String == "cook@example.com")
        #expect(sent["password"] as? String == "hunter2")
    }

    @Test("login stores the returned session")
    func loginStoresSession() async throws {
        let transport = StubTransport.json(authPayload)
        let (service, store) = makeService(transport: transport)

        try await service.login(email: "cook@example.com", password: "hunter2")

        #expect(store.accessToken == "jwt-token")
        #expect(store.user?.email == "cook@example.com")
        #expect(store.isAuthenticated)
    }

    @Test("register posts to auth/register and stores the session")
    func registerStoresSession() async throws {
        let transport = StubTransport.json(authPayload)
        let (service, store) = makeService(transport: transport)

        try await service.register(email: "cook@example.com", password: "hunter2")

        #expect(transport.lastRequest?.url?.path == "/auth/register")
        #expect(store.accessToken == "jwt-token")
    }

    @Test("a rejected login leaves the store signed out")
    func failedLoginLeavesStoreSignedOut() async throws {
        let transport = StubTransport.json(#"{"error":"bad credentials"}"#, status: 401)
        let (service, store) = makeService(transport: transport)

        await #expect(throws: APIError.self) {
            try await service.login(email: "cook@example.com", password: "wrong")
        }

        #expect(store.isAuthenticated == false)
    }

    @Test("bootstrap does nothing when signed out")
    func bootstrapSkipsWhenSignedOut() async {
        let transport = StubTransport.json(#"{"id":"u1"}"#)
        let (service, _) = makeService(transport: transport)

        await service.bootstrap()

        #expect(transport.requests.isEmpty)
    }

    @Test("bootstrap refreshes the user from /me")
    func bootstrapRefreshesUser() async throws {
        let transport = StubTransport.json(#"{"id":"u1","email":"new@example.com"}"#)
        let (service, store) = makeService(transport: transport)
        store.setSession(token: "t", user: User(id: "u1", email: "old@example.com", firstName: nil, lastName: nil))

        await service.bootstrap()

        #expect(transport.lastRequest?.url?.path == "/me")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer t")
        #expect(store.user?.email == "new@example.com")
    }

    @Test("bootstrap signs out when the stored token is rejected")
    func bootstrapSignsOutOnRejection() async {
        let transport = StubTransport.json("", status: 401)
        let (service, store) = makeService(transport: transport)
        store.setSession(token: "stale", user: User(id: "u1", email: nil, firstName: nil, lastName: nil))

        await service.bootstrap()

        #expect(store.isAuthenticated == false)
        #expect(store.user == nil)
    }
}
