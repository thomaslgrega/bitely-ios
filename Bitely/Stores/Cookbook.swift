import SwiftData
import SwiftUI

/// Which half of the Cookbook a Recipe files under. The split is authorship, not storage:
/// a Saved Recipe is another person's Shared Recipe kept here, so this user's own Shared
/// Recipes belong beside their Private ones — docs/design/app-flow.md, Cookbook.
enum CookbookSegment: String, CaseIterable, Hashable {
    case myRecipes = "My Recipes"
    case saved = "Saved"
}

/// A row of a segment. My Recipes merges two sources, so it can hold a Shared Recipe this
/// user wrote on another device and has no local copy of — that one has only what the
/// summary carries until it is opened.
enum CookbookEntry: Identifiable, Hashable {
    case local(Recipe)
    case shared(RecipeSummaryDTO)

    var id: String {
        switch self {
        case .local(let recipe): recipe.id.uuidString
        case .shared(let summary): summary.id
        }
    }

    var name: String {
        switch self {
        case .local(let recipe): recipe.name
        case .shared(let summary): summary.name
        }
    }

    var summary: RecipeSummary {
        switch self {
        case .local(let recipe): RecipeSummary(recipe)
        case .shared(let summary): RecipeSummary(summary)
        }
    }
}

/// Which of the device's Recipes this user wrote, for the length of a session.
///
/// The Recipes themselves come from SwiftData; `me/recipes` answers what the device cannot
/// know on its own — which Shared Recipes this user authored. That both separates their own
/// from the ones they saved and supplies the ones they wrote elsewhere.
@Observable
final class Cookbook {
    var segment: CookbookSegment = .myRecipes

    private var authored: [RecipeSummaryDTO] = []
    /// The session the authorship belongs to. Holding it rather than a flag means a sign-out
    /// or a switch of account cannot leave one user's authorship answering for another's.
    private var loadedForSession: String?

    @ObservationIgnored private let service: RecipeService
    @ObservationIgnored private let authStore: AuthStore

    init(service: RecipeService, authStore: AuthStore) {
        self.service = service
        self.authStore = authStore
    }

    private var authoredIds: Set<String> {
        Set(authored.map(\.id))
    }

    func segment(for recipe: Recipe) -> CookbookSegment {
        guard let remoteId = recipe.remoteId else { return .myRecipes }
        return authoredIds.contains(remoteId) ? .myRecipes : .saved
    }

    /// Saved is a pure local query. My Recipes adds the Shared Recipes this user authored
    /// that the device holds no copy of, so the segment is the whole of their own work
    /// rather than the part of it that happens to be on this phone.
    func entries(in segment: CookbookSegment, from recipes: [Recipe]) -> [CookbookEntry] {
        let local = recipes.filter { self.segment(for: $0) == segment }.map(CookbookEntry.local)
        guard segment == .myRecipes else { return local }

        let held = Set(recipes.compactMap(\.remoteId))
        let elsewhere = authored.filter { !held.contains($0.id) }.map(CookbookEntry.shared)
        return (local + elsewhere)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Signed out there is no authorship to ask about, and the split falls back to the one
    /// fact the device holds on its own: a Recipe with no remote id is Private.
    ///
    /// A failure keeps no answer rather than caching an empty one — an unanswered
    /// `me/recipes` would silently file this user's own Shared Recipes under Saved, so the
    /// next appearance asks again.
    func loadAuthorship() async {
        guard let session = authStore.accessToken else { return forgetAuthorship() }
        guard loadedForSession != session else { return }

        do {
            authored = try await service.getSharedRecipes()
            loadedForSession = session
        } catch {
            forgetAuthorship()
        }
    }

    /// Sharing hands back the Recipe the API just minted. Recording it keeps the local copy
    /// under My Recipes without re-reading the whole collection.
    func recordAuthorship(of shared: RecipeDetailDTO) {
        guard !authoredIds.contains(shared.id) else { return }
        authored.append(RecipeSummaryDTO(shared))
    }

    private func forgetAuthorship() {
        authored = []
        loadedForSession = nil
    }

    /// Editing is local for every Recipe in the Cookbook, whoever authored it: adding salt
    /// to a Saved Recipe writes to the local copy and never reaches the API, which is why
    /// gating sharing costs the user nothing — docs/design/app-flow.md, Cookbook.
    func commit(_ recipe: Recipe, into context: ModelContext) {
        guard recipe.modelContext == nil else { return }
        context.insert(recipe)
    }

    /// The local copy is the only copy of any edits made to it, which is why `SaveControl`
    /// confirms before this runs.
    func unsave(_ recipe: Recipe, from context: ModelContext) {
        context.delete(recipe)
    }
}

#if DEBUG
extension View {
    /// The stores every Recipe screen reads out of the environment. Previews wire them the
    /// way the app does, so a preview shows the screen rather than trapping on a missing one.
    func previewStores() -> some View {
        let authStore = AuthStore()
        let service = RecipeService(api: APIClient(authStore: authStore))
        return environment(authStore)
            .environment(service)
            .environment(Cookbook(service: service, authStore: authStore))
    }
}
#endif
