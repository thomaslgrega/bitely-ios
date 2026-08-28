//
//  A Name Query over the corpus of Shared Recipes: the user types a Recipe name and the
//  API answers with the closest matches it holds.
//
//  Every query is a request. The Feed holds fifty Shared Recipes by recency, so filtering
//  it would miss exactly the Recipe this screen exists to find, and the fuzzy match that
//  survives a misspelling is the API's — `bitelyapi` ADR-0004.
//
//  Nothing is cached: `RecipeStore` caches the Feed and each Category because they are a
//  small closed set the user revisits, and free text is neither.
//

import Foundation

/// What the search has to show. Results are the API's list in the API's order — closest
/// match first is the only ranking the corpus can offer, so nothing here re-sorts it.
enum RecipeNameSearchState: Equatable {
    /// Nothing worth searching has been typed yet.
    case prompt
    case loading
    case results([RecipeSummaryDTO])
    /// The query that found nothing, so the screen can show the user their own spelling.
    case noResults(query: String)
    case failed
}

/// Isolated to the main actor because SwiftUI observes `state` directly and the request
/// answers on another thread. It is owned by the screen and dies with it.
@MainActor
@Observable
final class RecipeNameSearch {
    /// The wait after the last keystroke. Typing is faster than this, so a query is sent
    /// for the thought the user finished rather than for every prefix on the way to it.
    static let debounce: Duration = .milliseconds(300)

    /// A single letter matches most of the corpus fuzzily, which is a request that costs
    /// something and tells the user nothing.
    static let minimumQueryLength = 2

    private(set) var query: String = ""
    private(set) var state: RecipeNameSearchState = .prompt

    /// The debounce and the request it leads to. Held so the next keystroke can cancel it,
    /// and so `deinit` can — which is why it is readable off the main actor: every write is
    /// made on it, and by `deinit` nothing else holds the search at all.
    @ObservationIgnored nonisolated(unsafe) private(set) var work: Task<Void, Never>?

    /// Bumped by every query. An answer carrying a stale number is dropped, so a slow
    /// response cannot overwrite the results of the query that replaced it.
    private var generation = 0

    @ObservationIgnored private let service: RecipeService
    @ObservationIgnored private let clock: any Clock<Duration>

    /// The clock is a seam so tests advance past the debounce instead of sleeping through
    /// it; the app takes the default.
    init(service: RecipeService, clock: any Clock<Duration> = ContinuousClock()) {
        self.service = service
        self.clock = clock
    }

    /// The screen has gone, so the request it was waiting on has nowhere to land.
    deinit { work?.cancel() }

    /// Takes what the field now holds and searches for it once the typing settles. Too
    /// short to search — cleared included — is the prompt, not an empty result.
    func setQuery(_ text: String) {
        query = text
        work?.cancel()

        let name = searchableQuery
        guard !name.isEmpty else {
            // An answer already in flight belongs to a query the user has abandoned, and
            // cancelling a request that has left is not enough to stop it landing.
            generation += 1
            work = nil
            state = .prompt
            return
        }
        work = search(for: name, debounced: true)
    }

    /// Re-runs the query the user is looking at, which is the only one the failure they
    /// tapped from belongs to. They have already waited, so this does not debounce.
    func retry() {
        let name = searchableQuery
        guard !name.isEmpty else { return }
        work?.cancel()
        work = search(for: name, debounced: false)
    }

    // MARK: - Details

    /// The query as something to send, or empty when there is not enough of it to send.
    private var searchableQuery: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= Self.minimumQueryLength ? trimmed : ""
    }

    /// The task holds the search weakly and touches it only between its own suspensions, so
    /// a screen dismissed while the request is out takes the search with it rather than
    /// waiting on a network it can no longer show. `deinit` then cancels what is left.
    private func search(for name: String, debounced: Bool) -> Task<Void, Never> {
        generation += 1
        let issued = generation
        let clock = clock
        let service = service

        return Task { [weak self] in
            if debounced {
                guard (try? await clock.sleep(for: Self.debounce)) != nil else { return }
            }
            guard self?.begin(issued) == true else { return }

            do {
                let recipes = try await service.getRecipesByName(name: name)
                self?.show(recipes, for: name, issued: issued)
            } catch {
                self?.report(error, issued: issued)
            }
        }
    }

    /// Whether this query is still the one the screen is waiting on, marking it as under
    /// way if it is.
    private func begin(_ issued: Int) -> Bool {
        guard issued == generation else { return false }
        state = .loading
        return true
    }

    private func show(_ recipes: [RecipeSummaryDTO], for name: String, issued: Int) {
        guard issued == generation else { return }
        state = recipes.isEmpty ? .noResults(query: name) : .results(recipes)
    }

    private func report(_ error: Error, issued: Int) {
        guard issued == generation else { return }
        // Leaving the screen mid-request is not something the user can retry, so a
        // cancellation goes back to the prompt the way `RecipeStore` goes idle.
        state = Self.isCancellation(error) ? .prompt : .failed
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let error = error as? URLError, error.code == .cancelled { return true }
        return false
    }
}
