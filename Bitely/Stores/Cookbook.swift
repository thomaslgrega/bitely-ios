import SwiftData
import SwiftUI

/// Which half of the Cookbook a Recipe files under. The split is authorship, not storage:
/// a Saved Recipe is another person's Shared Recipe kept here, so this user's own Shared
/// Recipes belong beside their Private ones — docs/design/app-flow.md, Cookbook.
enum CookbookSegment: String, CaseIterable, Hashable {
    case myRecipes = "My Recipes"
    case saved = "Saved"

    var other: CookbookSegment { self == .myRecipes ? .saved : .myRecipes }
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

/// Whether the device holds a copy of a corpus Recipe, answered by remote id. It covers
/// every local Recipe, this user's own Shared Recipes included, so it is not the Cookbook's
/// Saved segment.
///
/// A grid builds one of these from its own query over the device's Recipes; the alternative
/// — a tile asking for itself — is a query per tile, and Today's Picks draws fifty.
struct HeldRecipes {
    private let byRemoteId: [String: Recipe]

    init(_ recipes: [Recipe]) {
        byRemoteId = Dictionary(
            recipes.compactMap { recipe in recipe.remoteId.map { ($0, recipe) } },
            uniquingKeysWith: { first, _ in first }
        )
    }

    func recipe(for remoteId: String) -> Recipe? { byRemoteId[remoteId] }

    func contains(_ remoteId: String) -> Bool { byRemoteId[remoteId] != nil }
}

/// Which of the device's Recipes this user wrote, for the length of a session.
///
/// The Recipes themselves come from SwiftData; `me/recipes` answers what the device cannot
/// know on its own — which Shared Recipes this user authored. That both separates their own
/// from the ones they saved and supplies the ones they wrote elsewhere.
///
/// Main-actor bound because it writes the `ModelContext` the views query. A nonisolated
/// `async` method resumes on the global executor, so an insert after an `await` would land
/// off the main thread and `@Query` would never hear about it — SE-0338.
@MainActor
@Observable
final class Cookbook {
    var segment: CookbookSegment = .myRecipes

    private var authored: [RecipeSummaryDTO] = []
    /// Kept beside `authored` because a grid asks this of every tile it draws.
    private var authoredIds: Set<String> = []
    /// The session the authorship belongs to. Holding it rather than a flag means a sign-out
    /// or a switch of account cannot leave one user's authorship answering for another's.
    private var loadedForSession: String?
    /// The saves whose fetch is still in flight. The heart only fills on the insert, so a
    /// second tap during the fetch is the same save asked for twice and is dropped.
    private var saving: Set<String> = []

    @ObservationIgnored private let service: RecipeService
    @ObservationIgnored private let authStore: AuthStore

    init(service: RecipeService, authStore: AuthStore) {
        self.service = service
        self.authStore = authStore
    }

    /// Whether a grid offers a heart over a corpus Recipe. A Recipe this user wrote is
    /// already theirs and there is no keeping a second copy of it; until `me/recipes` has
    /// answered, the device cannot tell which those are, so an unanswered authorship offers
    /// nothing rather than offering the user their own work. Signed out there is no
    /// authorship to wait for.
    func offersSaving(of remoteId: String) -> Bool {
        guard authStore.accessToken != nil else { return true }
        guard loadedForSession != nil else { return false }
        return !authoredIds.contains(remoteId)
    }

    func segment(for recipe: Recipe) -> CookbookSegment {
        guard let remoteId = recipe.remoteId else { return .myRecipes }
        return authoredIds.contains(remoteId) ? .myRecipes : .saved
    }

    /// Whether `me/recipes` has answered for this session, which is what My Recipes needs
    /// before it can claim a name is absent: until then the Shared Recipes written on
    /// another device are not in `entries` at all. Signed out there is nothing to wait for.
    ///
    /// Compared against the current token rather than tested for nil, so the moment the
    /// account changes the answer goes back to unresolved instead of letting one user's
    /// authorship vouch for another's.
    var hasResolvedAuthorship: Bool {
        guard let session = authStore.accessToken else { return true }
        return loadedForSession == session
    }

    /// Saved is a pure local query. My Recipes adds the Shared Recipes this user authored
    /// that the device holds no copy of, so the segment is the whole of their own work
    /// rather than the part of it that happens to be on this phone.
    ///
    /// The query matches by name and is deliberately not fuzzy, so routing it through the
    /// API's trigram search would be the wrong fix — #48, docs/design/app-flow.md, Cookbook.
    /// Asking the other segment for its own count is all the cross-segment empty state needs.
    func entries(
        in segment: CookbookSegment,
        from recipes: [Recipe],
        matching query: String = ""
    ) -> [CookbookEntry] {
        let local = recipes.filter { self.segment(for: $0) == segment }.map(CookbookEntry.local)
        let all: [CookbookEntry]
        if segment == .myRecipes {
            let held = Set(recipes.compactMap(\.remoteId))
            let elsewhere = authored.filter { !held.contains($0.id) }.map(CookbookEntry.shared)
            all = (local + elsewhere)
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } else {
            all = local
        }

        let tokens = query.split(whereSeparator: \.isWhitespace)
        guard !tokens.isEmpty else { return all }
        return all.filter { entry in
            tokens.allSatisfy { token in
                entry.name.range(of: token, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
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
            authoredIds = Set(authored.map(\.id))
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
        authoredIds.insert(shared.id)
    }

    private func forgetAuthorship() {
        authored = []
        authoredIds = []
        loadedForSession = nil
    }

    /// Editing is local for every Recipe in the Cookbook, whoever authored it: adding salt
    /// to a Saved Recipe writes to the local copy and never reaches the API, which is why
    /// gating sharing costs the user nothing — docs/design/app-flow.md, Cookbook.
    func commit(_ recipe: Recipe, into context: ModelContext) {
        guard recipe.modelContext == nil else { return }
        context.insert(recipe)
    }

    /// Keeps a corpus Recipe. A grid carries summaries, which have neither ingredients nor
    /// instructions, so the copy comes from the Recipe in full rather than from the tile.
    ///
    /// A save that cannot reach the API keeps nothing: the heart stays unfilled and the tap
    /// is there to make again.
    func save(remoteId: String, into context: ModelContext) async {
        guard saving.insert(remoteId).inserted else { return }
        defer { saving.remove(remoteId) }

        guard let detail = try? await service.getRecipeById(id: remoteId) else { return }
        save(detail, into: context)
    }

    func save(_ detail: RecipeDetailDTO, into context: ModelContext) {
        guard !holds(detail.id, in: context) else { return }
        context.insert(Recipe(detail))
    }

    /// The detail screen bookmarks a Recipe the grid may already have kept, and a Recipe
    /// kept twice is two copies to edit and two to unsave.
    private func holds(_ remoteId: String, in context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { $0.remoteId == remoteId })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.isEmpty == false
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
    @MainActor
    func previewStores() -> some View {
        let authStore = AuthStore()
        let service = RecipeService(api: APIClient(authStore: authStore))
        return environment(authStore)
            .environment(service)
            .environment(Cookbook(service: service, authStore: authStore))
            .environment(RecipeStore(service: service))
    }
}
#endif
