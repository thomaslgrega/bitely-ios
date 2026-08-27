import Foundation
import SwiftData
import Testing
@testable import Bitely

private let detailJSON = """
{"id":"theirs","user_id":"u2","name":"Shakshuka","category":"Breakfast",
 "instructions":"Simmer, then crack the eggs in.","thumbnail_url":"https://example.invalid/s.jpg",
 "ingredients":[{"id":"i1","name":"eggs","measurement":"4"},
                {"id":"i2","name":"tomatoes","measurement":"400g"}],
 "calories":420,"total_cook_time":35}
"""

private let authorshipJSON = """
[{"id":"mine","name":"Short Rib","category":"Beef",
  "thumbnail_url":null,"calories":720,"total_cook_time":190}]
"""

/// Answers `me/recipes` with one authored Recipe and `recipes/{id}` with a Recipe in full.
@MainActor
private func makeCookbook() -> (Cookbook, StubTransport) {
    let transport = StubTransport { request in
        let path = request.url?.path ?? ""
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data((path == "/me/recipes" ? authorshipJSON : detailJSON).utf8), response)
    }
    let auth = AuthStore(defaults: makeIsolatedDefaults())
    auth.setSession(
        token: "token",
        user: User(id: "u1", email: "cook@example.com", firstName: "Nicky", lastName: nil)
    )
    let service = RecipeService(api: APIClient(authStore: auth, transport: transport))
    return (Cookbook(service: service, authStore: auth), transport)
}

@MainActor
private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: Recipe.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private func theirDetail() throws -> RecipeDetailDTO {
    try JSONDecoder().decode(RecipeDetailDTO.self, from: Data(detailJSON.utf8))
}

@MainActor
@Suite("Saving from the grid")
struct SavingFromTheGridTests {

    @Test("One pass over the device's Recipes answers every tile, keyed by remote id")
    func heldStateIsKeyedByRemoteId() {
        let held = HeldRecipes([
            Recipe(remoteId: "theirs", name: "Shakshuka", category: .breakfast),
            Recipe(name: "Sunday Ragu", category: .pasta)
        ])

        #expect(held.recipe(for: "theirs")?.name == "Shakshuka")
        #expect(held.recipe(for: "unheld") == nil)
    }

    @Test("A Recipe this user authored is theirs to keep, not to save")
    func authoredRecipesOfferNoHeart() async {
        let (cookbook, _) = makeCookbook()

        await cookbook.loadAuthorship()

        #expect(!cookbook.offersSaving(of: "mine"))
        #expect(cookbook.offersSaving(of: "theirs"))
    }

    @Test("Until me/recipes has answered, no tile offers to save this user their own work")
    func unansweredAuthorshipOffersNoHeart() async {
        let (cookbook, _) = makeCookbook()

        #expect(!cookbook.offersSaving(of: "mine"))
        #expect(!cookbook.offersSaving(of: "theirs"))

        await cookbook.loadAuthorship()

        #expect(cookbook.offersSaving(of: "theirs"))
    }

    @Test("Signed out there is no authorship to wait for, and every corpus Recipe is savable")
    func signedOutEveryRecipeIsSavable() {
        let auth = AuthStore(defaults: makeIsolatedDefaults())
        let service = RecipeService(api: APIClient(authStore: auth, transport: StubTransport.json("[]")))

        #expect(Cookbook(service: service, authStore: auth).offersSaving(of: "theirs"))
    }

    @Test("Two taps on one heart make one request and one copy")
    func aDoubleTapSavesOnce() async throws {
        let (cookbook, transport) = makeCookbook()
        let context = try makeContext()

        async let first: Void = cookbook.save(remoteId: "theirs", into: context)
        async let second: Void = cookbook.save(remoteId: "theirs", into: context)
        _ = await (first, second)
        try context.save()

        #expect(transport.requests.count == 1)
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)
    }

    @Test("Saving from a tile fetches the Recipe in full and keeps ingredients and instructions")
    func savingFromATileKeepsTheWholeRecipe() async throws {
        let (cookbook, transport) = makeCookbook()
        let context = try makeContext()

        await cookbook.save(remoteId: "theirs", into: context)
        try context.save()

        #expect(transport.requests.last?.url?.path == "/recipes/theirs")
        let stored = try #require(try context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(stored.remoteId == "theirs")
        #expect(stored.name == "Shakshuka")
        #expect(stored.category == .breakfast)
        #expect(stored.instructions == "Simmer, then crack the eggs in.")
        #expect(stored.ingredients.map(\.name).sorted() == ["eggs", "tomatoes"])
        #expect(stored.calories == 420)
        #expect(stored.totalCookTime == 35)
    }

    @Test("The tile fills straight off the insert, with no second query")
    func savingShowsUpInTheGridsOwnQuery() async throws {
        let (cookbook, _) = makeCookbook()
        let context = try makeContext()

        await cookbook.save(remoteId: "theirs", into: context)
        try context.save()

        let saved = HeldRecipes(try context.fetch(FetchDescriptor<Recipe>()))
        #expect(saved.recipe(for: "theirs") != nil)
    }

    @Test("Saving a Recipe the device already holds does not make a second copy")
    func savingTwiceKeepsOneCopy() async throws {
        let (cookbook, _) = makeCookbook()
        let context = try makeContext()

        await cookbook.save(remoteId: "theirs", into: context)
        try context.save()
        await cookbook.save(remoteId: "theirs", into: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)
    }

    @Test("A save that cannot reach the API leaves the Cookbook as it was")
    func aFailedSaveKeepsNothing() async throws {
        let auth = AuthStore(defaults: makeIsolatedDefaults())
        let service = RecipeService(
            api: APIClient(
                authStore: auth,
                transport: StubTransport.failing(URLError(.notConnectedToInternet))
            )
        )
        let cookbook = Cookbook(service: service, authStore: auth)
        let context = try makeContext()

        await cookbook.save(remoteId: "theirs", into: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).isEmpty)
    }

    @Test("Unsaving from a tile deletes the local copy the grid was reading")
    func unsavingRemovesTheLocalCopy() async throws {
        let (cookbook, _) = makeCookbook()
        let context = try makeContext()
        await cookbook.save(remoteId: "theirs", into: context)
        try context.save()

        let saved = try #require(HeldRecipes(try context.fetch(FetchDescriptor<Recipe>())).recipe(for: "theirs"))
        cookbook.unsave(saved, from: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).isEmpty)
    }

    @Test("A tile and the detail screen save the same Recipe, because both build it here")
    func bothSavePathsProduceTheSameRecipe() async throws {
        let (cookbook, _) = makeCookbook()
        let fromTile = try makeContext()
        let fromDetail = try makeContext()

        await cookbook.save(remoteId: "theirs", into: fromTile)
        cookbook.save(try theirDetail(), into: fromDetail)
        try fromTile.save()
        try fromDetail.save()

        let tiled = try #require(try fromTile.fetch(FetchDescriptor<Recipe>()).first)
        let detailed = try #require(try fromDetail.fetch(FetchDescriptor<Recipe>()).first)
        #expect(tiled.remoteId == detailed.remoteId)
        #expect(tiled.name == detailed.name)
        #expect(tiled.category == detailed.category)
        #expect(tiled.instructions == detailed.instructions)
        #expect(tiled.thumbnailURL == detailed.thumbnailURL)
        #expect(tiled.calories == detailed.calories)
        #expect(tiled.totalCookTime == detailed.totalCookTime)
        #expect(tiled.ingredients.map(\.name).sorted() == detailed.ingredients.map(\.name).sorted())
        #expect(tiled.ingredients.map(\.measurement).sorted() == detailed.ingredients.map(\.measurement).sorted())
    }
}
