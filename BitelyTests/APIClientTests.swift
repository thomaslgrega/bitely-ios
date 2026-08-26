import Foundation
import Testing
@testable import Bitely

@Suite("APIClient")
struct APIClientTests {
    private struct Payload: Decodable, Equatable {
        let value: String
    }

    private func makeClient(
        transport: StubTransport,
        token: String? = nil
    ) -> (APIClient, AuthStore) {
        let store = AuthStore(defaults: makeIsolatedDefaults())
        if let token {
            store.setSession(token: token, user: User(id: "u1", email: nil, firstName: nil, lastName: nil))
        }
        return (APIClient(authStore: store, transport: transport), store)
    }

    @Test("builds the URL from the base URL, path and query items")
    func buildsURL() async throws {
        let transport = StubTransport.json(#"{"value":"ok"}"#)
        let (client, _) = makeClient(transport: transport)

        let _: Payload = try await client.request(
            path: "recipes",
            query: [URLQueryItem(name: "category", value: "Chicken")]
        )

        let url = try #require(transport.lastRequest?.url)
        #expect(url.absoluteString == "\(client.baseURL.absoluteString)/recipes?category=Chicken")
    }

    @Test("builds a bare URL when there are no query items")
    func buildsURLWithoutQuery() async throws {
        let transport = StubTransport.json(#"{"value":"ok"}"#)
        let (client, _) = makeClient(transport: transport)

        let _: Payload = try await client.request(path: "recipes")

        let url = try #require(transport.lastRequest?.url)
        #expect(url.absoluteString == "\(client.baseURL.absoluteString)/recipes")
    }

    @Test("sends the method, JSON content type and body it was given")
    func sendsMethodAndBody() async throws {
        let transport = StubTransport.json(#"{"value":"ok"}"#)
        let (client, _) = makeClient(transport: transport, token: "t")
        let body = Data(#"{"name":"Soup"}"#.utf8)

        let _: Payload = try await client.request(
            path: "recipes",
            method: "POST",
            body: body,
            requiresAuth: true
        )

        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody == body)
    }

    @Test("attaches a bearer token when the call requires auth")
    func attachesBearerToken() async throws {
        let transport = StubTransport.json(#"{"value":"ok"}"#)
        let (client, _) = makeClient(transport: transport, token: "abc123")

        let _: Payload = try await client.request(path: "me/recipes", requiresAuth: true)

        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
    }

    @Test("omits the Authorization header when the call does not require auth")
    func omitsBearerTokenWhenNotRequired() async throws {
        let transport = StubTransport.json(#"{"value":"ok"}"#)
        let (client, _) = makeClient(transport: transport, token: "abc123")

        let _: Payload = try await client.request(path: "recipes")

        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("fails with 401 without touching the network when auth is required and no token is stored")
    func failsWhenTokenMissing() async throws {
        let transport = StubTransport.json(#"{"value":"ok"}"#)
        let (client, _) = makeClient(transport: transport)

        let error = await #expect(throws: APIError.self) {
            let _: Payload = try await client.request(path: "me/recipes", requiresAuth: true)
        }

        #expect(error?.statusCode == 401)
        #expect(transport.requests.isEmpty)
    }

    @Test("surfaces the status code and body of a non-2xx response")
    func surfacesServerError() async throws {
        let transport = StubTransport.json(#"{"error":"nope"}"#, status: 422)
        let (client, _) = makeClient(transport: transport)

        let error = await #expect(throws: APIError.self) {
            let _: Payload = try await client.request(path: "recipes")
        }

        #expect(error?.statusCode == 422)
        #expect(error?.body == #"{"error":"nope"}"#)
    }

    @Test("accepts the whole 2xx range", arguments: [200, 201, 204, 299])
    func acceptsSuccessStatuses(status: Int) async throws {
        let transport = StubTransport.json(#"{"value":"ok"}"#, status: status)
        let (client, _) = makeClient(transport: transport)

        let payload: Payload = try await client.request(path: "recipes")

        #expect(payload == Payload(value: "ok"))
    }

    @Test("rejects a response that is not an HTTP response")
    func rejectsNonHTTPResponse() async throws {
        let transport = StubTransport.nonHTTPResponse()
        let (client, _) = makeClient(transport: transport)

        let error = await #expect(throws: URLError.self) {
            let _: Payload = try await client.request(path: "recipes")
        }

        #expect(error?.code == .badServerResponse)
    }

    @Test("propagates a transport failure unchanged")
    func propagatesTransportFailure() async throws {
        let transport = StubTransport.failing(URLError(.notConnectedToInternet))
        let (client, _) = makeClient(transport: transport)

        let error = await #expect(throws: URLError.self) {
            let _: Payload = try await client.request(path: "recipes")
        }

        #expect(error?.code == .notConnectedToInternet)
    }

    @Test("fails when the body cannot be decoded into the expected type")
    func failsOnUndecodableBody() async throws {
        let transport = StubTransport.json(#"{"unexpected":true}"#)
        let (client, _) = makeClient(transport: transport)

        await #expect(throws: DecodingError.self) {
            let _: Payload = try await client.request(path: "recipes")
        }
    }

    @Suite("requestNoResponse")
    struct NoResponse {
        @Test("succeeds on 2xx and ignores the body")
        func succeedsOnSuccess() async throws {
            let transport = StubTransport.status(204)
            let store = AuthStore(defaults: makeIsolatedDefaults())
            store.setSession(token: "t", user: User(id: "u1", email: nil, firstName: nil, lastName: nil))
            let client = APIClient(authStore: store, transport: transport)

            try await client.requestNoResponse(path: "recipes/1", method: "DELETE", requiresAuth: true)

            #expect(transport.lastRequest?.httpMethod == "DELETE")
        }

        @Test("throws APIError on a non-2xx response")
        func throwsOnFailure() async throws {
            let transport = StubTransport.json("gone", status: 404)
            let store = AuthStore(defaults: makeIsolatedDefaults())
            let client = APIClient(authStore: store, transport: transport)

            let error = await #expect(throws: APIError.self) {
                try await client.requestNoResponse(path: "recipes/1", method: "DELETE")
            }

            #expect(error?.statusCode == 404)
            #expect(error?.body == "gone")
        }
    }
}
