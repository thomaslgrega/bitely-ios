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

    @Test("The two segments partition the Cookbook")
    func segmentsPartitionTheCookbook() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let all = [privateRecipe(), someoneElses(), ownShared()]

        #expect(cookbook.recipes(in: .myRecipes, from: all).map(\.name) == ["Sunday Ragu", "Short Rib"])
        #expect(cookbook.recipes(in: .saved, from: all).map(\.name) == ["Shakshuka"])
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
        #expect(cookbook.recipes(in: .myRecipes, from: [privateRecipe(), someoneElses()]).map(\.name)
                == ["Sunday Ragu"])
    }

    @Test("Sharing a Private Recipe leaves it under My Recipes without another request")
    func sharingKeepsARecipeUnderMyRecipes() async {
        let (cookbook, transport, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let recipe = privateRecipe()

        recipe.remoteId = "fresh"
        cookbook.recordAuthorship(of: "fresh")

        #expect(cookbook.segment(for: recipe) == .myRecipes)
        #expect(transport.requests.count == 1)
    }

    @Test("Signing out forgets whose Shared Recipes were whose")
    func signingOutForgetsAuthorship() async {
        let (cookbook, _, auth) = makeCookbook()
        await cookbook.loadAuthorship()

        auth.signOut()
        cookbook.forgetAuthorship()

        #expect(cookbook.segment(for: ownShared()) == .saved)
    }

    @Test("Unsaving deletes the local copy and the segment loses it")
    func unsavingDeletesTheLocalCopy() throws {
        let (cookbook, _, _) = makeCookbook()
        let context = try makeContext()
        let saved = someoneElses()
        context.insert(saved)
        try context.save()

        cookbook.unsave(saved, from: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).isEmpty)
    }

    @Test("Editing a Saved Recipe writes to the local copy and asks the API for nothing")
    func editingASavedRecipeStaysLocal() throws {
        let (_, transport, _) = makeCookbook()
        let context = try makeContext()
        let saved = Recipe(
            remoteId: "theirs",
            name: "Shakshuka",
            category: .breakfast,
            ingredients: [Ingredient(name: "eggs", measurement: "4")]
        )
        context.insert(saved)
        try context.save()

        saved.ingredients.append(Ingredient(name: "salt", measurement: "1 tsp"))
        try context.save()

        let stored = try #require(try context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(stored.ingredients.count == 2)
        #expect(transport.requests.isEmpty)
    }
}

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
