import Foundation

@Observable
final class RecipeService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getRecipeById(id: String) async throws -> RecipeDetailDTO {
        try await api.request(path: "recipes/\(id)")
    }

    /// The Feed: the corpus by recency of sharing, capped by the API — `bitelyapi`
    /// ADR-0005. A `category` query item here would answer something else entirely.
    func getFeed() async throws -> [RecipeSummaryDTO] {
        try await api.request(path: "recipes")
    }

    func getRecipesByCategory(category: FoodCategory) async throws -> [RecipeSummaryDTO] {
        try await api.request(path: "recipes", query: [URLQueryItem(name: "category", value: category.rawValue)])
    }

    /// A Name Query: the corpus matched fuzzily against a Recipe name, closest first and
    /// capped by the API — `bitelyapi` ADR-0004. The endpoint composes `name` with
    /// `category`; nothing in the app asks it to.
    func getRecipesByName(name: String) async throws -> [RecipeSummaryDTO] {
        try await api.request(path: "recipes", query: [URLQueryItem(name: "name", value: name)])
    }

    func getSharedRecipes() async throws -> [RecipeSummaryDTO] {
        try await api.request(path: "me/recipes", requiresAuth: true)
    }

    func deleteSharedRecipe(id: String) async throws {
        try await api.requestNoResponse(path: "recipes/\(id)", method: "DELETE", requiresAuth: true)
    }

    func createRecipe(recipe: CreateRecipeRequest) async throws -> RecipeDetailDTO {
        let data = try JSONEncoder().encode(recipe)
        return try await api.request(path: "recipes", method: "POST", body: data, requiresAuth: true)
    }

    func editRecipe(recipe: RecipeDetailDTO) async throws {
        let data = try JSONEncoder().encode(recipe)
        try await api.requestNoResponse(path: "recipes/\(recipe.id)", method: "PUT", body: data, requiresAuth: true)
    }
}

extension RecipeService: CorpusMatching {
    /// The Pantry Items go up as the user typed them, and the endpoint needs no
    /// session: the corpus is publicly readable.
    func matchCorpus(pantryItems: [String]) async throws -> [RecipeMatch] {
        let data = try JSONEncoder().encode(pantryItems)
        let matches: [RecipeMatchDTO] = try await api.request(path: "recipes/match", method: "POST", body: data)
        return matches.map(RecipeMatch.init)
    }
}
