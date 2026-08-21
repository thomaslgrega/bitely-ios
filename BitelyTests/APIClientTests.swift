import XCTest
@testable import Bitely

final class APIClientTests: XCTestCase {
    struct EchoResponse: Decodable, Equatable {
        let value: String
    }

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

    func testRequestIncludesAuthHeaderWhenRequired() async throws {
        let store = AuthStore()
        store.setSession(token: "jwt-123", user: User(id: "u1", email: "a@b.com", firstName: nil, lastName: nil))
        let client = APIClient(authStore: store)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer jwt-123")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/me")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = Data("{\"value\":\"ok\"}".utf8)
            return (response, data)
        }

        let response: EchoResponse = try await client.request(path: "me", requiresAuth: true)
        XCTAssertEqual(response, EchoResponse(value: "ok"))
    }

    func testRequestThrows401WhenAuthRequiredButTokenMissing() async {
        let store = AuthStore()
        let client = APIClient(authStore: store)

        do {
            let _: EchoResponse = try await client.request(path: "me", requiresAuth: true)
            XCTFail("Expected APIError")
        } catch let error as APIError {
            XCTAssertEqual(error.statusCode, 401)
            XCTAssertEqual(error.body, "Missing access token")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRequestThrowsAPIErrorForNon2xxAndIncludesBody() async {
        let store = AuthStore()
        let client = APIClient(authStore: store)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = Data("backend exploded".utf8)
            return (response, data)
        }

        do {
            let _: EchoResponse = try await client.request(path: "recipes")
            XCTFail("Expected APIError")
        } catch let error as APIError {
            XCTAssertEqual(error.statusCode, 500)
            XCTAssertEqual(error.body, "backend exploded")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRequestPassesQueryItems() async throws {
        let store = AuthStore()
        let client = APIClient(authStore: store)

        MockURLProtocol.requestHandler = { request in
            let queryItems = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
            XCTAssertEqual(queryItems?.first(where: { $0.name == "category" })?.value, "Beef")

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{\"value\":\"ok\"}".utf8))
        }

        let _: EchoResponse = try await client.request(path: "recipes", query: [URLQueryItem(name: "category", value: "Beef")])
    }

    func testRequestNoResponseSucceedsOn2xx() async throws {
        let store = AuthStore()
        let client = APIClient(authStore: store)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await client.requestNoResponse(path: "recipes/1", method: "DELETE")
    }

    func testRequestThrowsDecodingErrorForInvalidPayload() async {
        let store = AuthStore()
        let client = APIClient(authStore: store)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{\"wrong\":\"shape\"}".utf8))
        }

        do {
            let _: EchoResponse = try await client.request(path: "me")
            XCTFail("Expected DecodingError")
        } catch is DecodingError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
