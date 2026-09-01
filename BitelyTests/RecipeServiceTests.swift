import Foundation
import Testing
@testable import Bitely

@Suite("RecipeService")
struct RecipeServiceTests {
    private let detailPayload = #"""
    {
      "id": "r1",
      "user_id": "u9",
      "name": "Carbonara",
      "category": "Pasta",
      "instructions": "Boil water.",
      "image_url": null,
      "ingredients": [],
      "calories": 780,
      "total_cook_time": 25
    }
    """#

    private func makeService(transport: StubTransport, signedIn: Bool = true) -> RecipeService {
        let store = AuthStore(defaults: makeIsolatedDefaults())
        if signedIn {
            store.setSession(token: "t", user: User(id: "u9", email: nil, firstName: nil, lastName: nil))
        }
        return RecipeService(api: APIClient(authStore: store, transport: transport))
    }

    @Test("getRecipeById requests the recipe by path")
    func getRecipeById() async throws {
        let transport = StubTransport.json(detailPayload)
        let service = makeService(transport: transport)

        let recipe = try await service.getRecipeById(id: "r1")

        #expect(transport.lastRequest?.url?.path == "/recipes/r1")
        #expect(transport.lastRequest?.httpMethod == "GET")
        #expect(recipe.name == "Carbonara")
        #expect(recipe.totalCookTime == 25)
    }

    @Test("getFeed asks for recipes with no query at all")
    func getFeed() async throws {
        let transport = StubTransport.json("[]")
        let service = makeService(transport: transport)

        _ = try await service.getFeed()

        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/recipes")
        #expect(components.queryItems == nil)
    }

    @Test("getRecipesByCategory sends the category as a query item", arguments: FoodCategory.allCases)
    func getRecipesByCategory(category: FoodCategory) async throws {
        let transport = StubTransport.json("[]")
        let service = makeService(transport: transport)

        _ = try await service.getRecipesByCategory(category: category)

        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/recipes")
        #expect(components.queryItems == [URLQueryItem(name: "category", value: category.rawValue)])
    }

    @Test("getRecipesByName sends the Name Query and no Category alongside it")
    func getRecipesByName() async throws {
        let transport = StubTransport.json("[]")
        let service = makeService(transport: transport)

        _ = try await service.getRecipesByName(name: "shakshuka")

        let url = try #require(transport.lastRequest?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/recipes")
        #expect(components.queryItems == [URLQueryItem(name: "name", value: "shakshuka")])
    }

    @Test("getSharedRecipes authenticates against me/recipes")
    func getSharedRecipes() async throws {
        let transport = StubTransport.json("[]")
        let service = makeService(transport: transport)

        _ = try await service.getSharedRecipes()

        #expect(transport.lastRequest?.url?.path == "/me/recipes")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer t")
    }

    @Test("getSharedRecipes fails when signed out")
    func getSharedRecipesRequiresAuth() async throws {
        let transport = StubTransport.json("[]")
        let service = makeService(transport: transport, signedIn: false)

        let error = await #expect(throws: APIError.self) {
            _ = try await service.getSharedRecipes()
        }

        #expect(error?.statusCode == 401)
    }

    @Test("deleteSharedRecipe sends an authenticated DELETE")
    func deleteSharedRecipe() async throws {
        let transport = StubTransport.status(204)
        let service = makeService(transport: transport)

        try await service.deleteSharedRecipe(id: "r1")

        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.url?.path == "/recipes/r1")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer t")
    }

    @Test("createRecipe POSTs the encoded request body")
    func createRecipe() async throws {
        let transport = StubTransport.json(detailPayload, status: 201)
        let service = makeService(transport: transport)
        let request = CreateRecipeRequest(
            name: "Carbonara",
            category: .pasta,
            instructions: "Boil water.",
            imageKey: nil,
            ingredients: [CreateIngredientRequest(name: "Spaghetti", measurement: "200 g")],
            calories: 780,
            totalCookTime: 25
        )

        let created = try await service.createRecipe(recipe: request)

        let sent = try #require(transport.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.path == "/recipes")

        let body = try #require(sent.httpBody)
        let object = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["total_cook_time"] as? Int == 25)
        #expect(created.id == "r1")
    }

    @Test("editRecipe PUTs to the recipe's own path")
    func editRecipe() async throws {
        let transport = StubTransport.status(200)
        let service = makeService(transport: transport)
        let detail = try JSONDecoder().decode(RecipeDetailDTO.self, from: Data(detailPayload.utf8))

        try await service.editRecipe(recipe: detail)

        let sent = try #require(transport.lastRequest)
        #expect(sent.httpMethod == "PUT")
        #expect(sent.url?.path == "/recipes/r1")

        let body = try #require(sent.httpBody)
        let object = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["id"] as? String == "r1")
        #expect(object["total_cook_time"] as? Int == 25)
    }

    private let matchPayload = #"""
    [
      {
        "id": "r1",
        "name": "Shakshuka",
        "category": "Breakfast",
        "image_url": null,
        "matched_ingredients": ["eggs", "tomatoes"],
        "missing_ingredients": ["harissa"],
        "coverage": 0.6666666666666666
      }
    ]
    """#

    @Test("matchCorpus POSTs the Pantry Items to the match endpoint")
    func matchCorpusPostsPantryItems() async throws {
        let transport = StubTransport.json(matchPayload)
        let service = makeService(transport: transport)

        _ = try await service.matchCorpus(pantryItems: ["2 Cups of FLOUR", "eggs"])

        let sent = try #require(transport.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.path == "/recipes/match")

        let body = try #require(sent.httpBody)
        let items = try #require(try JSONSerialization.jsonObject(with: body) as? [String])
        #expect(items == ["2 Cups of FLOUR", "eggs"])
    }

    @Test("matchCorpus needs no session, because the corpus is publicly readable")
    func matchCorpusIsUnauthenticated() async throws {
        let transport = StubTransport.json(matchPayload)
        let service = makeService(transport: transport, signedIn: false)

        let matches = try await service.matchCorpus(pantryItems: ["eggs"])

        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(matches.count == 1)
    }

    @Test("A corpus Match derives its Coverage from the two Ingredient lists")
    func matchCorpusDerivesCoverage() async throws {
        let transport = StubTransport.json(matchPayload)
        let service = makeService(transport: transport)

        let match = try #require(try await service.matchCorpus(pantryItems: ["eggs"]).first)

        #expect(match.recipeID == "r1")
        #expect(match.recipeName == "Shakshuka")
        #expect(match.matchedCount == 2)
        #expect(match.totalCount == 3)
        #expect(match.missingIngredients == ["harissa"])
    }

    @Test("A corpus that matches nothing is an empty list, not a failure")
    func matchCorpusEmptyList() async throws {
        let transport = StubTransport.json("[]")
        let service = makeService(transport: transport)

        #expect(try await service.matchCorpus(pantryItems: ["saffron"]).isEmpty)
    }
}
