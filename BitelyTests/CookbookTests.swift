import Foundation
import SwiftData
import Testing
@testable import Bitely

private func sharedRecipes(_ ids: [String]) -> String {
    let objects = ids.map { id in
        """
        {"id":"\(id)","name":"Recipe \(id)","category":"Pasta",
         "thumbnail_url":null,"calories":500,"total_cook_time":30}
        """
    }
    return "[\(objects.joined(separator: ","))]"
}

/// What `me/recipes` answers, so a test can fail the request and then let it succeed.
private final class Authorship: @unchecked Sendable {
    var ids = ["mine"]
    var error: Error?
}

@MainActor
private func makeCookbook(
    _ authorship: Authorship = Authorship(),
    signedIn: Bool = true
) -> (Cookbook, StubTransport, AuthStore) {
    let transport = StubTransport { request in
        if let error = authorship.error { throw error }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(sharedRecipes(authorship.ids).utf8), response)
    }
    let auth = AuthStore(defaults: makeIsolatedDefaults())
    if signedIn {
        auth.setSession(
            token: "token",
            user: User(id: "u1", email: "cook@example.com", firstName: "Nicky", lastName: nil)
        )
    }
    let service = RecipeService(api: APIClient(authStore: auth, transport: transport))
    return (Cookbook(service: service, authStore: auth), transport, auth)
}

/// Each test gets its own store, so inserts and deletes cannot reach another running test.
@MainActor
private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: Recipe.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private func privateRecipe() -> Recipe { Recipe(name: "Sunday Ragu", category: .pasta) }
private func someoneElses() -> Recipe { Recipe(remoteId: "theirs", name: "Shakshuka", category: .breakfast) }
private func ownShared() -> Recipe { Recipe(remoteId: "mine", name: "Short Rib", category: .beef) }

private func sharedDetail(id: String, name: String) -> RecipeDetailDTO {
    RecipeDetailDTO(
        id: id,
        userId: "u1",
        name: name,
        category: .pasta,
        instructions: nil,
        thumbnailUrl: nil,
        ingredients: [],
        calories: nil,
        totalCookTime: nil
    )
}

@MainActor
@Suite("Cookbook")
struct CookbookTests {

    @Test("A Recipe with no remote id is Private, and a Private Recipe is one of My Recipes")
    func privateRecipesAreMine() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()

        #expect(cookbook.segment(for: privateRecipe()) == .myRecipes)
    }

    @Test("A Recipe whose remote id is not in me/recipes is another person's, and files under Saved")
    func otherPeoplesSharedRecipesAreSaved() async throws {
        let (cookbook, transport, _) = makeCookbook()

        await cookbook.loadAuthorship()

        let url = try #require(transport.lastRequest?.url)
        #expect(url.path == "/me/recipes")
        #expect(cookbook.segment(for: someoneElses()) == .saved)
    }

    @Test("A Recipe whose remote id is in me/recipes is this user's own Shared Recipe")
    func ownSharedRecipesAreMine() async {
        let (cookbook, _, _) = makeCookbook()

        await cookbook.loadAuthorship()

        #expect(cookbook.segment(for: ownShared()) == .myRecipes)
    }

    @Test("The two segments partition what the device holds")
    func segmentsPartitionTheCookbook() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let all = [privateRecipe(), someoneElses(), ownShared()]

        #expect(cookbook.entries(in: .myRecipes, from: all).map(\.name) == ["Short Rib", "Sunday Ragu"])
        #expect(cookbook.entries(in: .saved, from: all).map(\.name) == ["Shakshuka"])
    }

    @Test("My Recipes merges in a Shared Recipe this user wrote on another device")
    func myRecipesMergesInRecipesWrittenElsewhere() async {
        let authorship = Authorship()
        authorship.ids = ["mine", "elsewhere"]
        let (cookbook, _, _) = makeCookbook(authorship)
        await cookbook.loadAuthorship()

        let entries = cookbook.entries(in: .myRecipes, from: [privateRecipe(), ownShared()])

        #expect(entries.map(\.name) == ["Recipe elsewhere", "Short Rib", "Sunday Ragu"])
        #expect(entries.contains { $0.id == "elsewhere" })
    }

    @Test("A Shared Recipe the device already holds is listed once, from the local copy")
    func aHeldSharedRecipeIsNotListedTwice() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()

        let entries = cookbook.entries(in: .myRecipes, from: [ownShared()])

        #expect(entries.map(\.name) == ["Short Rib"])
    }

    @Test("Saved stays a pure local query — nobody else's Recipes are fetched into it")
    func savedIsALocalQuery() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()

        #expect(cookbook.entries(in: .saved, from: []).isEmpty)
    }

    @Test("Authorship is asked for once a session")
    func authorshipIsAskedForOnce() async {
        let (cookbook, transport, _) = makeCookbook()

        await cookbook.loadAuthorship()
        await cookbook.loadAuthorship()

        #expect(transport.requests.count == 1)
    }

    @Test("A failed me/recipes is asked for again the next time the Cookbook appears")
    func failedAuthorshipIsAskedAgain() async {
        let authorship = Authorship()
        authorship.error = URLError(.notConnectedToInternet)
        let (cookbook, transport, _) = makeCookbook(authorship)

        await cookbook.loadAuthorship()
        #expect(cookbook.segment(for: ownShared()) == .saved)

        authorship.error = nil
        await cookbook.loadAuthorship()

        #expect(transport.requests.count == 2)
        #expect(cookbook.segment(for: ownShared()) == .myRecipes)
    }

    @Test("Signed out, nothing is asked for and Private Recipes still show under My Recipes")
    func signedOutStillListsPrivateRecipes() async {
        let (cookbook, transport, _) = makeCookbook(signedIn: false)

        await cookbook.loadAuthorship()

        #expect(transport.requests.isEmpty)
        #expect(cookbook.entries(in: .myRecipes, from: [privateRecipe(), someoneElses()]).map(\.name)
                == ["Sunday Ragu"])
    }

    @Test("Sharing a Private Recipe leaves it under My Recipes without another request")
    func sharingKeepsARecipeUnderMyRecipes() async {
        let (cookbook, transport, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let recipe = privateRecipe()

        recipe.remoteId = "fresh"
        cookbook.recordAuthorship(of: sharedDetail(id: "fresh", name: "Sunday Ragu"))

        #expect(cookbook.segment(for: recipe) == .myRecipes)
        #expect(transport.requests.count == 1)
    }

    @Test("Signing out forgets whose Shared Recipes were whose, without being told to")
    func signingOutForgetsAuthorship() async {
        let (cookbook, transport, auth) = makeCookbook()
        await cookbook.loadAuthorship()

        auth.signOut()
        await cookbook.loadAuthorship()

        #expect(cookbook.segment(for: ownShared()) == .saved)
        #expect(cookbook.entries(in: .myRecipes, from: []).isEmpty)
        #expect(transport.requests.count == 1)
    }

    @Test("A second account does not inherit the first one's authorship")
    func aNewSessionAsksAgain() async {
        let (cookbook, transport, auth) = makeCookbook()
        await cookbook.loadAuthorship()

        auth.signOut()
        auth.setSession(
            token: "another",
            user: User(id: "u2", email: "other@example.com", firstName: nil, lastName: nil)
        )
        await cookbook.loadAuthorship()

        #expect(transport.requests.count == 2)
    }

    @Test("The heart confirms first: a tap leaves the Recipe in place, Remove deletes it")
    func unsavingConfirmsBeforeDeleting() throws {
        let (cookbook, _, _) = makeCookbook()
        let context = try makeContext()
        let saved = someoneElses()
        cookbook.commit(saved, into: context)
        try context.save()

        // The tap raises the confirmation rather than unsaving, so nothing is gone yet.
        #expect(SaveControl(isSaved: true).tap == .confirmUnsave)
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)

        cookbook.unsave(saved, from: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).isEmpty)
        #expect(cookbook.entries(in: .saved, from: []).isEmpty)
    }

    @Test("Editing a Saved Recipe writes to the local copy and asks the API for nothing")
    func editingASavedRecipeStaysLocal() async throws {
        let (cookbook, transport, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let requestsAfterLoad = transport.requests.count
        let context = try makeContext()
        let saved = Recipe(
            remoteId: "theirs",
            name: "Shakshuka",
            category: .breakfast,
            ingredients: [Ingredient(name: "eggs", measurement: "4")]
        )
        cookbook.commit(saved, into: context)
        try context.save()

        saved.ingredients.append(Ingredient(name: "salt", measurement: "1 tsp"))
        cookbook.commit(saved, into: context)
        try context.save()

        let stored = try #require(try context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(stored.ingredients.count == 2)
        #expect(cookbook.segment(for: stored) == .saved)
        #expect(transport.requests.count == requestsAfterLoad)
    }

    @Test("Committing a Recipe the store already holds does not insert a second copy")
    func committingTwiceKeepsOneCopy() throws {
        let (cookbook, _, _) = makeCookbook()
        let context = try makeContext()
        let recipe = privateRecipe()

        cookbook.commit(recipe, into: context)
        cookbook.commit(recipe, into: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)
    }
}

@MainActor
@Suite("Share control")
struct ShareControlTests {

    @Test("Only a Recipe with no remote id is Private")
    func onlyRecipesWithNoRemoteIdArePrivate() {
        #expect(privateRecipe().isPrivate)
        #expect(!someoneElses().isPrivate)
        #expect(!ownShared().isPrivate)
    }

    @Test("Share is offered on a Private Recipe and withheld on one already shared")
    func offeredOnlyOnAPrivateRecipe() {
        #expect(ShareControl(isPrivate: true, isAuthenticated: true).isOffered)
        #expect(!ShareControl(isPrivate: false, isAuthenticated: true).isOffered)
    }

    @Test("Signed in, the action asks the user to confirm")
    func signedInConfirms() {
        #expect(ShareControl(isPrivate: true, isAuthenticated: true).tap == .confirmShare)
    }

    @Test("Signed out, the action presents auth at the moment of sharing")
    func signedOutPresentsAuth() {
        #expect(ShareControl(isPrivate: true, isAuthenticated: false).tap == .presentAuth)
    }
}
