//
//  The Name Query screen's state: what it asks the API for, when it asks, and what it
//  draws from the answer. The service goes through `StubTransport`, so the request itself
//  is asserted off what was recorded.
//

import Foundation
import Testing
@testable import Bitely

// MARK: - Fixtures

private func summaryPayload(_ names: String...) -> String {
    let recipes = names.enumerated().map { index, name in
        """
        {"id":"r\(index)","name":"\(name)","category":"Breakfast","image_url":null,"calories":420,"total_cook_time":20}
        """
    }
    return "[\(recipes.joined(separator: ","))]"
}

@MainActor
private func makeSearch(transport: HTTPTransport, clock: TestClock) -> RecipeNameSearch {
    let authStore = AuthStore(defaults: makeIsolatedDefaults())
    let service = RecipeService(api: APIClient(authStore: authStore, transport: transport))
    return RecipeNameSearch(service: service, clock: clock)
}

/// Types a query and runs the debounce out, leaving the request that follows it finished.
@MainActor
private func type(_ query: String, into search: RecipeNameSearch, clock: TestClock) async {
    search.setQuery(query)
    await clock.advance(by: RecipeNameSearch.debounce)
    await search.work?.value
}

/// Runs a search up to the point where the request is in flight, then drops the search the
/// way a dismissed screen does — the local reference dies with this call — and answers with
/// a weak handle on it and the task it left behind.
@MainActor
private func dismissedMidRequest(
    transport: HTTPTransport,
    clock: TestClock
) async -> (value: WeakHandle<RecipeNameSearch>, work: Task<Void, Never>?) {
    let search = makeSearch(transport: transport, clock: clock)
    search.setQuery("shakshuka")
    await clock.advance(by: RecipeNameSearch.debounce)
    return (WeakHandle(search), search.work)
}

private func names(of state: RecipeNameSearchState) -> [String]? {
    guard case .results(let recipes) = state else { return nil }
    return recipes.map(\.name)
}

/// A transport that holds the answer to one Name Query until the test releases it, so a
/// superseded response can be made to land after the one that replaced it. Any other query
/// is answered straight away.
private final class HoldingAnswer: HTTPTransport, @unchecked Sendable {
    private let heldQuery: String
    private let responder: (URLRequest) -> (Data, URLResponse)
    private let lock = NSLock()
    private var held: CheckedContinuation<Void, Never>?
    private var isReleased = false

    init(to heldQuery: String, responder: @escaping (URLRequest) -> (Data, URLResponse)) {
        self.heldQuery = heldQuery
        self.responder = responder
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        if nameQuery(of: request) == heldQuery {
            await withCheckedContinuation { continuation in
                let resumeNow: Bool = lock.withLock {
                    guard !isReleased else { return true }
                    held = continuation
                    return false
                }
                if resumeNow { continuation.resume() }
            }
        }
        return responder(request)
    }

    func release() {
        let continuation: CheckedContinuation<Void, Never>? = lock.withLock {
            isReleased = true
            defer { held = nil }
            return held
        }
        continuation?.resume()
    }
}

private func nameQuery(of request: URLRequest) -> String {
    guard let url = request.url,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return "" }
    return components.queryItems?.first { $0.name == "name" }?.value ?? ""
}

private func jsonResponder(
    _ bodyForQuery: @escaping (String) -> String
) -> (URLRequest) -> (Data, URLResponse) {
    { request in
        let url = request.url ?? URL(string: "https://example.invalid")!
        let query = nameQuery(of: request)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(bodyForQuery(query).utf8), response)
    }
}

// MARK: - Tests

@Suite("Name search")
@MainActor
struct RecipeNameSearchTests {

    @Test("The search asks for the typed name and nothing else")
    func requestCarriesTheName() async throws {
        let transport = StubTransport.json(summaryPayload("Shakshuka"))
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        await type("shakshuka", into: search, clock: clock)

        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/recipes")
        #expect(components.queryItems == [URLQueryItem(name: "name", value: "shakshuka")])
        #expect(names(of: search.state) == ["Shakshuka"])
    }

    @Test("A query under two characters asks for nothing", arguments: ["", " ", "s"])
    func shortQueriesAreNotSearched(query: String) async {
        let transport = StubTransport.json(summaryPayload("Shakshuka"))
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        await type(query, into: search, clock: clock)

        #expect(transport.requests.isEmpty)
        #expect(search.state == .prompt)
    }

    @Test("Keystrokes in quick succession make one request, for the last of them")
    func rapidKeystrokesMakeOneRequest() async throws {
        let transport = StubTransport.json(summaryPayload("Shakshuka"))
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        search.setQuery("sh")
        await clock.advance(by: .milliseconds(100))
        search.setQuery("sha")
        await clock.advance(by: .milliseconds(100))
        search.setQuery("shak")
        await clock.advance(by: RecipeNameSearch.debounce)
        await search.work?.value

        #expect(transport.requests.count == 1)
        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "name", value: "shak")])
    }

    @Test("A superseded answer does not overwrite the newer query's results")
    func supersededAnswerIsDropped() async {
        let transport = HoldingAnswer(
            to: "sha",
            responder: jsonResponder { query in
                query == "sha" ? summaryPayload("Stale") : summaryPayload("Shakshuka")
            }
        )
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        search.setQuery("sha")
        await clock.advance(by: RecipeNameSearch.debounce)
        let superseded = search.work

        await type("shakshuka", into: search, clock: clock)
        #expect(names(of: search.state) == ["Shakshuka"])

        transport.release()
        await superseded?.value

        #expect(names(of: search.state) == ["Shakshuka"])
    }

    @Test("An empty answer is no results, not the prompt")
    func emptyAnswerIsNoResults() async {
        let transport = StubTransport.json("[]")
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        await type("shakshuka", into: search, clock: clock)

        #expect(search.state == .noResults(query: "shakshuka"))
    }

    @Test("Clearing the query before the debounce runs out asks for nothing")
    func clearingBeforeTheRequestAsksForNothing() async {
        let transport = StubTransport.json(summaryPayload("Shakshuka"))
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        search.setQuery("shakshuka")
        search.setQuery("")

        #expect(search.state == .prompt)

        await clock.advance(by: RecipeNameSearch.debounce)
        await search.work?.value
        #expect(transport.requests.isEmpty)
    }

    @Test("Clearing the query returns to the prompt, and the answer in flight cannot undo it")
    func clearingOutlivesTheRequestInFlight() async {
        let transport = HoldingAnswer(
            to: "shakshuka",
            responder: jsonResponder { _ in summaryPayload("Shakshuka") }
        )
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        search.setQuery("shakshuka")
        await clock.advance(by: RecipeNameSearch.debounce)
        let abandoned = search.work

        search.setQuery("")
        #expect(search.state == .prompt)

        transport.release()
        await abandoned?.value

        #expect(search.state == .prompt)
    }

    @Test("A thrown error fails the screen, and retry re-runs the same query")
    func failureAndRetry() async throws {
        let transport = StubTransport.failing(URLError(.notConnectedToInternet))
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        await type("shakshuka", into: search, clock: clock)
        #expect(search.state == .failed)

        search.retry()
        await search.work?.value

        #expect(transport.requests.count == 2)
        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "name", value: "shakshuka")])
    }

    @Test("A search whose screen goes away mid-request is released, not held by its own work")
    func dismissalMidRequestReleasesTheSearch() async {
        let transport = HoldingAnswer(
            to: "shakshuka",
            responder: jsonResponder { _ in summaryPayload("Shakshuka") }
        )
        let clock = TestClock()
        let (search, work) = await dismissedMidRequest(transport: transport, clock: clock)

        // The request has not answered yet: nothing but the task in flight could be
        // keeping the search alive.
        #expect(search.value == nil)

        transport.release()
        await work?.value
    }

    @Test("A cancelled request is not a failure")
    func cancellationIsNotFailure() async {
        let transport = StubTransport.failing(CancellationError())
        let clock = TestClock()
        let search = makeSearch(transport: transport, clock: clock)

        await type("shakshuka", into: search, clock: clock)

        #expect(search.state == .prompt)
    }
}
