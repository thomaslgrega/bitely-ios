import Foundation

/// Discover's Recipes for the length of a session: the Feed once, then each Category the
/// user actually taps, cached until relaunch. Nothing is persisted and nothing expires.
///
/// Chips fetch their Category rather than filtering the Feed — the Feed is capped by
/// recency, so a filtered Feed cannot tell the user whether a short grid is the filter or
/// the catalogue. See `bitelyapi` ADR-0005 and docs/design/app-flow.md.
@Observable
final class RecipeStore {
    /// What the grid has to draw right now, so the view branches once instead of
    /// assembling this from a loading flag, an error and two collections.
    enum Contents: Equatable {
        case loading
        case recipes([RecipeSummaryDTO])
        case failed
    }

    private enum Load: Equatable {
        case idle
        case loading
        case loaded([RecipeSummaryDTO])
        case failed
    }

    private(set) var selectedCategory: FoodCategory?

    private var feed: Load = .idle
    private var categories: [FoodCategory: Load] = [:]

    @ObservationIgnored private let service: RecipeService

    init(service: RecipeService) {
        self.service = service
    }

    var heading: String { selectedCategory?.rawValue ?? "Today's Picks" }

    func contents(on date: Date) -> Contents {
        switch load(for: selectedCategory) {
        case .idle, .loading: .loading
        case .failed: .failed
        case .loaded(let recipes): .recipes(selectedCategory == nil ? todaysPicks(on: date) : recipes)
        }
    }

    /// The Feed's own Recipes in the day's order — the same list `contents(on:)` shows
    /// with no chip selected.
    func todaysPicks(on date: Date) -> [RecipeSummaryDTO] {
        guard case .loaded(let recipes) = feed else { return [] }
        return picks(from: recipes, on: date)
    }

    /// Every appearance of the screen calls this; only the first one asks the API, and a
    /// failure waits for `retry()` rather than reissuing on the next appearance.
    func loadFeed() async {
        guard feed == .idle else { return }
        feed = .loading
        feed = await fetch { try await service.getFeed() }
    }

    func select(_ category: FoodCategory?) async {
        selectedCategory = category
        guard let category, load(for: category) == .idle else { return }
        categories[category] = .loading
        categories[category] = await fetch { try await service.getRecipesByCategory(category: category) }
    }

    /// Retries whatever the user is looking at, which is the only thing the error state
    /// they tapped from belongs to.
    func retry() async {
        if let selectedCategory {
            categories[selectedCategory] = .idle
            await select(selectedCategory)
        } else {
            feed = .idle
            await loadFeed()
        }
    }

    private func load(for category: FoodCategory?) -> Load {
        guard let category else { return feed }
        return categories[category] ?? .idle
    }

    /// A cancelled request is the screen going away mid-flight, not a failure the user
    /// can act on, so it goes back to idle and the next appearance asks again.
    private func fetch(_ request: () async throws -> [RecipeSummaryDTO]) async -> Load {
        do {
            return .loaded(try await request())
        } catch is CancellationError {
            return .idle
        } catch let error as URLError where error.code == .cancelled {
            return .idle
        } catch {
            return .failed
        }
    }

    /// Today's Picks: the Feed rotated by the day, so the grid is stable until the user's
    /// next midnight and changes over it. Pure in `date` — the caller owns the clock.
    private func picks(from recipes: [RecipeSummaryDTO], on date: Date) -> [RecipeSummaryDTO] {
        guard recipes.count > 1 else { return recipes }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let offset = ((day % recipes.count) + recipes.count) % recipes.count
        return Array(recipes[offset...] + recipes[..<offset])
    }
}
