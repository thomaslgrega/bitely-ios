import Foundation
@testable import Bitely

/// An HTTPTransport that answers from a canned closure and records what it was asked.
///
/// Each test builds its own instance, so tests stay independent under Swift Testing's
/// parallel execution. Requests are recorded verbatim — including `httpBody`, which a
/// URLProtocol-based mock would have converted to a stream.
final class StubTransport: HTTPTransport, @unchecked Sendable {
    typealias Responder = (URLRequest) throws -> (Data, URLResponse)

    private let lock = NSLock()
    private var recorded: [URLRequest] = []
    private let responder: Responder

    init(responder: @escaping Responder) {
        self.responder = responder
    }

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }

    var lastRequest: URLRequest? {
        lock.withLock { recorded.last }
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        lock.withLock { recorded.append(request) }
        return try responder(request)
    }
}

extension StubTransport {
    /// Responds with `body` and the given status code.
    static func json(_ body: String, status: Int = 200) -> StubTransport {
        StubTransport { request in
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.invalid")!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (Data(body.utf8), response)
        }
    }

    /// Responds with an empty body and the given status code.
    static func status(_ code: Int) -> StubTransport {
        json("", status: code)
    }

    /// Responds with something that is not an HTTPURLResponse.
    static func nonHTTPResponse() -> StubTransport {
        StubTransport { request in
            let response = URLResponse(
                url: request.url ?? URL(string: "https://example.invalid")!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (Data(), response)
        }
    }

    /// Fails every request with the given error.
    static func failing(_ error: Error) -> StubTransport {
        StubTransport { _ in throw error }
    }
}

/// A UserDefaults suite unique to one test, so nothing leaks between tests or into the app.
func makeIsolatedDefaults() -> UserDefaults {
    UserDefaults(suiteName: "BitelyTests.\(UUID().uuidString)")!
}
