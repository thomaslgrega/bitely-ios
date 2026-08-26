import Foundation
import SwiftData

/// Which half of the Cookbook a Recipe files under. The split is authorship, not storage:
/// a Saved Recipe is another person's Shared Recipe kept here, so this user's own Shared
/// Recipes belong beside their Private ones — docs/design/app-flow.md, Cookbook.
enum CookbookSegment: String, CaseIterable, Hashable {
    case myRecipes = "My Recipes"
    case saved = "Saved"
}

extension Recipe {
    /// Written here and never shared. The only kind of Recipe the Share action is offered
    /// on, and the only kind whose remote id is still absent.
    var isPrivate: Bool { remoteId == nil }
}

/// Whether a Recipe's detail screen offers Share, and what one tap does. Signed out it
/// presents auth at the moment of sharing, where the intent is unambiguous and there is no
/// half-filled form to lose — docs/design/app-flow.md, Cookbook.
struct ShareControl: Equatable {
    enum Tap: Equatable {
        case confirmShare
        case presentAuth
    }

    let isPrivate: Bool
    let isAuthenticated: Bool

    /// A Saved Recipe is someone else's work and cannot be re-shared under this user's
    /// name; one already shared has nowhere to go.
    var isOffered: Bool { isPrivate }

    var tap: Tap { isAuthenticated ? .confirmShare : .presentAuth }
}

extension ShareControl {
    init(recipe: Recipe, isAuthenticated: Bool) {
        self.init(isPrivate: recipe.isPrivate, isAuthenticated: isAuthenticated)
    }
}

/// Which of the device's Recipes this user wrote, for the length of a session.
///
/// The Recipes themselves come from SwiftData; the only thing the API is asked for is the
/// set of remote ids this user authored, which is what separates their own Shared Recipes
/// from the ones they saved from other people.
@Observable
final class Cookbook {
    var segment: CookbookSegment = .myRecipes

    private var authoredIds: Set<String> = []
    private var hasLoaded = false

    @ObservationIgnored private let service: RecipeService
    @ObservationIgnored private let authStore: AuthStore

    init(service: RecipeService, authStore: AuthStore) {
        self.service = service
        self.authStore = authStore
    }

    func segment(for recipe: Recipe) -> CookbookSegment {
        guard let remoteId = recipe.remoteId else { return .myRecipes }
        return authoredIds.contains(remoteId) ? .myRecipes : .saved
    }

    func recipes(in segment: CookbookSegment, from recipes: [Recipe]) -> [Recipe] {
        recipes.filter { self.segment(for: $0) == segment }
    }

    /// Signed out there is no authorship to ask about, and the split falls back to the one
    /// fact the device holds on its own: a Recipe with no remote id is Private.
    ///
    /// A failure leaves the session unloaded rather than caching an empty answer — an
    /// unanswered `me/recipes` would silently file this user's own Shared Recipes under
    /// Saved, so the next appearance asks again.
    func loadAuthorship() async {
        guard authStore.isAuthenticated, !hasLoaded else { return }
        do {
            authoredIds = Set(try await service.getSharedRecipes().map(\.id))
            hasLoaded = true
        } catch {
            hasLoaded = false
        }
    }

    /// Sharing hands back the remote id the API just minted. Recording it keeps the Recipe
    /// under My Recipes without re-reading the whole collection.
    func recordAuthorship(of remoteId: String) {
        authoredIds.insert(remoteId)
    }

    /// Authorship belongs to a session. The next one asks again.
    func forgetAuthorship() {
        authoredIds = []
        hasLoaded = false
    }

    /// The local copy is the only copy of any edits made to it, which is why `SaveControl`
    /// confirms before this runs.
    func unsave(_ recipe: Recipe, from context: ModelContext) {
        context.delete(recipe)
    }
}
