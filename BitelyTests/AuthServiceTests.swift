import XCTest
@testable import Bitely

@MainActor
final class AuthServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
        UserDefaults.standard.removeObject(forKey: "access_token")
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        UserDefaults.standard.removeObject(forKey: "access_token")
        super.tearDown()
    }

    func testLoginStoresSessionFromAPIResponse() async throws {
        let store = AuthStore()
        let api = APIClient(authStore: store)
        let service = AuthService(api: api, authStore: store)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/auth/login")
            XCTAssertEqual(request.httpMethod, "POST")

            let json = """
            {
              "access_token": "new-token",
              "user": {
                "id": "u1",
                "email": "test@example.com",
                "first_name": "Test",
                "last_name": "User"
              }
            }
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        try await service.login(email: "test@example.com", password: "pass123")

        XCTAssertEqual(store.accessToken, "new-token")
        XCTAssertEqual(store.user?.id, "u1")
        XCTAssertEqual(store.user?.email, "test@example.com")
    }

    func testBootstrapSignsOutWhenMeRequestFails() async {
        let store = AuthStore()
        store.setSession(token: "stale-token", user: User(id: "u1", email: "x@y.com", firstName: nil, lastName: nil))
        let api = APIClient(authStore: store)
        let service = AuthService(api: api, authStore: store)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/me")
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data("unauthorized".utf8))
        }

        await service.bootstrap()

        XCTAssertFalse(store.isAuthenticated)
        XCTAssertNil(store.user)
    }

    func testBootstrapRefreshesUserOnSuccess() async {
        let store = AuthStore()
        store.setSession(token: "good-token", user: User(id: "old", email: "old@example.com", firstName: nil, lastName: nil))
        let api = APIClient(authStore: store)
        let service = AuthService(api: api, authStore: store)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer good-token")
            let json = """
            {
              "id": "u2",
              "email": "new@example.com",
              "first_name": "New",
              "last_name": "User"
            }
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        await service.bootstrap()

        XCTAssertTrue(store.isAuthenticated)
        XCTAssertEqual(store.user?.id, "u2")
        XCTAssertEqual(store.user?.email, "new@example.com")
    }

    func testRegisterStoresSessionFromAPIResponse() async throws {
        let store = AuthStore()
        let api = APIClient(authStore: store)
        let service = AuthService(api: api, authStore: store)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/auth/register")
            XCTAssertEqual(request.httpMethod, "POST")

            let json = """
            {
              "access_token": "reg-token",
              "user": {
                "id": "u99",
                "email": "new@example.com",
                "first_name": null,
                "last_name": null
              }
            }
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        try await service.register(email: "new@example.com", password: "securepass")

        XCTAssertEqual(store.accessToken, "reg-token")
        XCTAssertEqual(store.user?.id, "u99")
    }
}
