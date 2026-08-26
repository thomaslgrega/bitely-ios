import Foundation
import Testing
@testable import Bitely

private func summaries(_ names: [String], category: String = "Pasta") -> String {
    let objects = names.enumerated().map { index, name in
        """
        {"id":"r\(index)","name":"\(name)","category":"\(category)",
         "thumbnail_url":null,"calories":500,"total_cook_time":30}
        """
    }
    return "[\(objects.joined(separator: ","))]"
}

/// What the API answers, per collection, so a test can fail one request and leave the
/// other working.
private final class Corpus: @unchecked Sendable {
    var feed = summaries(["Shakshuka", "Carbonara", "Short Rib"])
    var category = summaries(["Seared Scallops"], category: "Seafood")
    var feedError: Error?
    var categoryError: Error?
}

private func makeStore(_ corpus: Corpus) -> (RecipeStore, StubTransport) {
    let transport = StubTransport { request in
        let isCategoryQuery = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
            .queryItems?.contains { $0.name == "category" } ?? false

        if let error = isCategoryQuery ? corpus.categoryError : corpus.feedError {
            throw error
        }

        let body = isCategoryQuery ? corpus.category : corpus.feed
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(body.utf8), response)
    }
    let auth = AuthStore(defaults: makeIsolatedDefaults())
    let service = RecipeService(api: APIClient(authStore: auth, transport: transport))
    return (RecipeStore(service: service), transport)
}

private let aDay = Date(timeIntervalSince1970: 1_772_000_000)
private let nextDay = aDay.addingTimeInterval(86_400)

private func names(_ contents: RecipeStore.Contents) -> [String] {
    guard case .recipes(let recipes) = contents else { return [] }
    return recipes.map(\.name)
}

@Suite("Recipe store")
struct RecipeStoreTests {

    @Test("A cold launch asks for the Feed once and shows Today's Picks from it")
    func coldLaunchLoadsTheFeed() async throws {
        let (store, transport) = makeStore(Corpus())

        await store.loadFeed()

        #expect(transport.requests.count == 1)
        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/recipes")
        #expect(components.queryItems == nil)
        #expect(names(store.contents(on: aDay)).sorted() == ["Carbonara", "Shakshuka", "Short Rib"])
    }

    @Test("A second appearance of the screen issues no further request")
    func loadedFeedIsNotRefetched() async {
        let (store, transport) = makeStore(Corpus())

        await store.loadFeed()
        await store.loadFeed()

        #expect(transport.requests.count == 1)
    }

    @Test("A failed Feed leaves an error the user can retry from")
    func failedFeedIsRetryable() async {
        let corpus = Corpus()
        corpus.feedError = URLError(.notConnectedToInternet)
        let (store, transport) = makeStore(corpus)

        await store.loadFeed()
        #expect(store.contents(on: aDay) == .failed)

        corpus.feedError = nil
        await store.retry()

        #expect(transport.requests.count == 2)
        #expect(names(store.contents(on: aDay)).count == 3)
    }

    @Test(
        "A cancelled Feed request is the screen going away, not an error",
        arguments: [URLError(.cancelled) as Error, CancellationError()]
    )
    func cancelledFeedIsNotAFailure(cancellation: Error) async {
        let corpus = Corpus()
        corpus.feedError = cancellation
        let (store, transport) = makeStore(corpus)

        await store.loadFeed()
        #expect(store.contents(on: aDay) == .loading)

        corpus.feedError = nil
        await store.loadFeed()

        #expect(transport.requests.count == 2)
        #expect(names(store.contents(on: aDay)).count == 3)
    }

    @Test("A cancelled Category request is asked again the next time the chip is selected")
    func cancelledCategoryIsNotAFailure() async {
        let corpus = Corpus()
        corpus.categoryError = CancellationError()
        let (store, transport) = makeStore(corpus)
        await store.loadFeed()
        await store.select(.seafood)

        corpus.categoryError = nil
        await store.select(nil)
        await store.select(.seafood)

        #expect(transport.requests.count == 3)
        #expect(names(store.contents(on: aDay)) == ["Seared Scallops"])
    }

    @Test("Selecting a chip fetches that Category once and narrows the grid to it")
    func selectingAChipFetchesItsCategoryOnce() async throws {
        let (store, transport) = makeStore(Corpus())
        await store.loadFeed()

        await store.select(.seafood)

        #expect(transport.requests.count == 2)
        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.queryItems == [URLQueryItem(name: "category", value: "Seafood")])
        #expect(names(store.contents(on: aDay)) == ["Seared Scallops"])
        #expect(store.heading == "Seafood")
    }

    @Test("Deselecting restores the picks, and re-selecting a cached Category asks for nothing")
    func cachedCategoryAndDeselectionAreFree() async {
        let (store, transport) = makeStore(Corpus())
        await store.loadFeed()
        await store.select(.seafood)

        await store.select(nil)
        #expect(names(store.contents(on: aDay)).count == 3)
        #expect(store.heading == "Today's Picks")

        await store.select(.seafood)
        #expect(names(store.contents(on: aDay)) == ["Seared Scallops"])
        #expect(transport.requests.count == 2)
    }

    @Test("A failed Category leaves the Feed intact behind it")
    func failedCategoryLeavesTheFeed() async {
        let corpus = Corpus()
        corpus.categoryError = URLError(.notConnectedToInternet)
        let (store, transport) = makeStore(corpus)
        await store.loadFeed()

        await store.select(.seafood)
        #expect(store.contents(on: aDay) == .failed)

        await store.select(nil)
        #expect(names(store.contents(on: aDay)).count == 3)
        #expect(transport.requests.count == 2)
    }

    @Test("A failed Category is retryable on its own")
    func failedCategoryIsRetryable() async {
        let corpus = Corpus()
        corpus.categoryError = URLError(.notConnectedToInternet)
        let (store, _) = makeStore(corpus)
        await store.loadFeed()
        await store.select(.seafood)

        corpus.categoryError = nil
        await store.retry()

        #expect(names(store.contents(on: aDay)) == ["Seared Scallops"])
    }

    @Test("Today's Picks is stable within a day and different the next")
    func picksAreStableWithinADay() async {
        let (store, _) = makeStore(Corpus())
        await store.loadFeed()

        #expect(store.todaysPicks(on: aDay).map(\.name) == store.todaysPicks(on: aDay).map(\.name))
        #expect(store.todaysPicks(on: aDay).map(\.name) != store.todaysPicks(on: nextDay).map(\.name))
    }

    @Test("Today's Picks is the whole Feed, only rearranged")
    func picksRearrangeTheFeed() async {
        let (store, _) = makeStore(Corpus())
        await store.loadFeed()

        #expect(store.todaysPicks(on: nextDay).map(\.name).sorted()
                == ["Carbonara", "Shakshuka", "Short Rib"])
    }

    @Test("An empty Feed is empty picks rather than a failure")
    func emptyFeedIsNotAFailure() async {
        let corpus = Corpus()
        corpus.feed = "[]"
        let (store, _) = makeStore(corpus)

        await store.loadFeed()

        #expect(store.contents(on: aDay) == .recipes([]))
    }

    @Test("The grid says it is loading until the first Feed arrives")
    func startsLoading() {
        let (store, _) = makeStore(Corpus())

        #expect(store.contents(on: aDay) == .loading)
    }
}
