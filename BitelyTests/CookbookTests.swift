import Foundation
import SwiftData
import Testing
import UIKit
@testable import Bitely

private func sharedRecipes(_ ids: [String]) -> String {
    let objects = ids.map { id in
        """
        {"id":"\(id)","name":"Recipe \(id)","category":"Pasta",
         "image_url":null,"calories":500,"total_cook_time":30}
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
        imageUrl: nil,
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

    @Test("A query narrows the segment to the names holding it")
    func aQueryNarrowsTheSegment() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let all = [privateRecipe(), ownShared()]

        let entries = cookbook.entries(in: .myRecipes, from: all, matching: "rib")

        #expect(entries.map(\.name) == ["Short Rib"])
    }

    @Test("Every word must appear, in any order")
    func aMultiWordQueryIgnoresWordOrder() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let tikka = Recipe(name: "Chicken Tikka Masala", category: .chicken)

        #expect(cookbook.entries(in: .myRecipes, from: [tikka], matching: "tikka chicken")
                .map(\.name) == ["Chicken Tikka Masala"])
        #expect(cookbook.entries(in: .myRecipes, from: [tikka], matching: "tikka lamb").isEmpty)
    }

    @Test("Case and accents are ignored", arguments: ["ragu", "RAGÙ", "Ragu"])
    func caseAndDiacriticsAreIgnored(query: String) async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let ragu = Recipe(name: "Sunday Ragù", category: .pasta)

        #expect(cookbook.entries(in: .myRecipes, from: [ragu], matching: query).count == 1)
    }

    @Test("A query of nothing but whitespace is no query at all", arguments: ["", "   ", "\n\t"])
    func anEmptyQueryReturnsTheWholeSegment(query: String) async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let all = [privateRecipe(), ownShared()]

        #expect(cookbook.entries(in: .myRecipes, from: all, matching: query).map(\.name)
                == cookbook.entries(in: .myRecipes, from: all).map(\.name))
    }

    @Test("A Shared Recipe written elsewhere is filtered like any other row")
    func theFilterCoversRecipesWrittenElsewhere() async {
        let authorship = Authorship()
        authorship.ids = ["mine", "elsewhere"]
        let (cookbook, _, _) = makeCookbook(authorship)
        await cookbook.loadAuthorship()

        let entries = cookbook.entries(in: .myRecipes, from: [ownShared()], matching: "elsewhere")

        #expect(entries.map(\.id) == ["elsewhere"])
    }

    @Test("A name held only in Saved does not answer under My Recipes")
    func theFilterDoesNotReachAcrossSegments() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let all = [privateRecipe(), someoneElses()]

        #expect(cookbook.entries(in: .myRecipes, from: all, matching: "shakshuka").isEmpty)
        #expect(cookbook.entries(in: .saved, from: all, matching: "shakshuka").map(\.name)
                == ["Shakshuka"])
    }

    @Test("A query matching nothing here is counted in the other segment")
    func aQueryMatchingNothingIsCountedInTheOtherSegment() async {
        let (cookbook, _, _) = makeCookbook()
        await cookbook.loadAuthorship()
        let all = [privateRecipe(), someoneElses(), ownShared()]

        #expect(cookbook.entries(in: .myRecipes, from: all, matching: "shak").isEmpty)
        #expect(cookbook.entries(in: .saved, from: all, matching: "shak").count == 1)
        #expect(cookbook.segment.other == .saved)
        #expect(CookbookSegment.saved.other == .myRecipes)
    }

    @Test("Authorship reports whether me/recipes has answered for this session")
    func authorshipReportsWhetherItHasResolved() async {
        let authorship = Authorship()
        authorship.error = URLError(.notConnectedToInternet)
        let (cookbook, _, _) = makeCookbook(authorship)

        #expect(!cookbook.hasResolvedAuthorship)
        await cookbook.loadAuthorship()
        #expect(!cookbook.hasResolvedAuthorship)

        authorship.error = nil
        await cookbook.loadAuthorship()

        #expect(cookbook.hasResolvedAuthorship)
    }

    @Test("A second account's authorship is unresolved until it has answered for itself")
    func authorshipIsNotResolvedByAnotherAccountsAnswer() async {
        let (cookbook, _, auth) = makeCookbook()
        await cookbook.loadAuthorship()
        #expect(cookbook.hasResolvedAuthorship)

        auth.signOut()
        auth.setSession(
            token: "another",
            user: User(id: "u2", email: "other@example.com", firstName: nil, lastName: nil)
        )

        #expect(!cookbook.hasResolvedAuthorship)
    }

    @Test("Signed out there is no authorship left to wait for")
    func signedOutAuthorshipIsResolved() async {
        let (cookbook, _, _) = makeCookbook(signedIn: false)

        await cookbook.loadAuthorship()

        #expect(cookbook.hasResolvedAuthorship)
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

@Suite("Cookbook screen")
struct CookbookScreenTests {

    private func screen(
        segment: CookbookSegment = .myRecipes,
        query: String = "",
        matches: Int = 0,
        held: Int = 0,
        elsewhere: Int = 0,
        hasResolvedAuthorship: Bool = true
    ) -> CookbookScreen {
        CookbookScreen(
            segment: segment,
            query: query,
            matches: matches,
            held: held,
            matchesElsewhere: elsewhere,
            hasResolvedAuthorship: hasResolvedAuthorship
        )
    }

    @Test("A segment with something in it draws the grid and offers the filter")
    func aFilledSegmentDrawsTheGrid() {
        let screen = screen(matches: 3, held: 3)

        #expect(screen.offersFilter)
        #expect(screen.placeholder == .grid)
    }

    @Test("A segment holding nothing offers what to do rather than a way to filter nothing")
    func anEmptySegmentOffersNoFilter() {
        let screen = screen()

        #expect(!screen.offersFilter)
        #expect(screen.placeholder == .emptyCollection)
    }

    @Test("A live query keeps its own field, so it can always be cleared")
    func aLiveQueryKeepsItsField() {
        #expect(screen(query: "ragu", held: 4).offersFilter)
        #expect(screen(query: "ragu").offersFilter)
    }

    @Test("A live query is never answered with the creation flow")
    func aLiveQueryIsNeverAnsweredWithTheCreationFlow() {
        // My Recipes reads as empty while `me/recipes` is unanswered, and offering to write
        // a recipe to someone who is looking for one answers a question they did not ask.
        #expect(screen(query: "ragu", hasResolvedAuthorship: false).placeholder
                == .unresolvedAuthorship)
        #expect(screen(query: "ragu").placeholder == .noMatches)
    }

    @Test("A match one segment over is offered ahead of any caveat about authorship")
    func aMatchElsewhereBeatsTheSoftening() {
        #expect(screen(query: "ragu", elsewhere: 2, hasResolvedAuthorship: false).placeholder
                == .matchesElsewhere(2))
        #expect(screen(query: "ragu", held: 4, elsewhere: 1).placeholder == .matchesElsewhere(1))
    }

    @Test("Saved never softens: nothing about it waits on me/recipes")
    func savedDoesNotSoften() {
        #expect(screen(segment: .saved, query: "ragu", held: 4, hasResolvedAuthorship: false)
                .placeholder == .noMatches)
    }

    @Test("A whitespace-only query is no query at all", arguments: ["", "   "])
    func whitespaceIsNoQuery(query: String) {
        let screen = screen(query: query)

        #expect(!screen.offersFilter)
        #expect(screen.placeholder == .emptyCollection)
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

    @Test("A share in flight says so and cannot be asked for again")
    func inFlightSaysSo() {
        let control = ShareControl(isPrivate: true, isAuthenticated: true, shareState: .inFlight)

        #expect(control.label == "Sharing…")
        #expect(!control.isEnabled)
    }

    /// The user already confirmed the share that failed, so the retry does not ask again.
    @Test("A failed share offers the retry directly")
    func failedOffersRetry() {
        let control = ShareControl(isPrivate: true, isAuthenticated: true, shareState: .failed)

        #expect(control.label == "Share failed — tap to retry")
        #expect(control.isEnabled)
        #expect(control.tap == .share)
    }

    /// There is no token refresh (#58), so an expired session is the user's to resolve.
    @Test("A share refused for the session offers auth rather than a retry")
    func expiredSessionOffersAuth() {
        let control = ShareControl(isPrivate: true, isAuthenticated: true, shareState: .needsSignIn)

        #expect(control.label == "Sign in again to share")
        #expect(control.tap == .presentAuth)
    }
}

private let sharedDetail = #"""
{"id":"new","user_id":"u1","name":"Sunday Ragu","category":"Pasta","instructions":null,
 "image_url":"https://pub.example/recipes/new/9f3.jpg","ingredients":[],
 "calories":null,"total_cook_time":null}
"""#

fileprivate enum ShareStep: String, CaseIterable {
    case presign, put, create
}

/// Which leg of the share fails, mutable so one test can let a retry through.
private final class ShareFaults: @unchecked Sendable {
    var step: ShareStep?
    var status: Int
    /// Runs as each leg is answered, so a test can change the world mid-share.
    var during: ((ShareStep) -> Void)?

    init(step: ShareStep? = nil, status: Int = 500) {
        self.step = step
        self.status = status
    }
}

/// Answers all three legs of a share — the presign, R2's PUT and `POST /recipes` — from one
/// stub, so a test reads the requests in the order the share made them.
private func shareTransport(_ faults: ShareFaults) -> StubTransport {
    StubTransport { request in
        let url = request.url!
        let body: String
        let code: Int
        switch (url.host, url.path) {
        case (_, "/recipes/images"):
            faults.during?(.presign)
            (body, code) = faults.step == .presign
                ? ("", faults.status)
                : (#"{"upload_url":"https://r2.example/incoming/abc?sig=1","key":"incoming/abc"}"#, 200)
        case ("r2.example", _):
            faults.during?(.put)
            (body, code) = faults.step == .put ? ("", faults.status) : ("", 200)
        default:
            faults.during?(.create)
            (body, code) = faults.step == .create ? ("", faults.status) : (sharedDetail, 201)
        }
        let response = HTTPURLResponse(
            url: url, statusCode: code, httpVersion: "HTTP/1.1", headerFields: nil
        )!
        return (Data(body.utf8), response)
    }
}

@MainActor
private func makeSharer(
    _ faults: ShareFaults = ShareFaults()
) -> (Cookbook, StubTransport, AuthStore) {
    let transport = shareTransport(faults)
    let auth = AuthStore(defaults: makeIsolatedDefaults())
    auth.setSession(
        token: "token",
        user: User(id: "u1", email: "cook@example.com", firstName: "Nicky", lastName: nil)
    )
    let service = RecipeService(
        api: APIClient(authStore: auth, transport: transport),
        uploads: PresignedUploader(transport: transport)
    )
    return (Cookbook(service: service, authStore: auth), transport, auth)
}

/// A real JPEG, because a share puts the stored bytes back through the encoder and bytes
/// that decode to nothing are not a photo.
private func jpeg(width: CGFloat, height: CGFloat) -> Data {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        .image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        }
    return image.jpegData(compressionQuality: 0.8)!
}

private func photographedRecipe() -> Recipe {
    let recipe = privateRecipe()
    recipe.imageData = jpeg(width: 400, height: 300)
    return recipe
}

private func otherAccount() -> User {
    User(id: "u2", email: "someone@example.com", firstName: "Sam", lastName: nil)
}

@MainActor
@Suite("Sharing a Recipe")
struct SharingTests {

    @Test("A photographed Recipe stages its bytes, then claims the key on the create")
    func sharesInThreeSteps() async throws {
        let (cookbook, transport, _) = makeSharer()

        await cookbook.share(photographedRecipe())

        #expect(transport.requests.count == 3)
        #expect(transport.requests[0].url?.path == "/recipes/images")
        #expect(transport.requests[1].url?.host == "r2.example")
        #expect(transport.requests[1].httpMethod == "PUT")

        let create = transport.requests[2]
        #expect(create.httpMethod == "POST")
        #expect(create.url?.path == "/recipes")
        let body = try #require(create.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["image_key"] as? String == "incoming/abc")
    }

    @Test("A Recipe with no photo goes straight to the create, carrying no key")
    func aPhotolessRecipeSkipsTheUpload() async throws {
        let (cookbook, transport, _) = makeSharer()

        await cookbook.share(privateRecipe())

        #expect(transport.requests.count == 1)
        #expect(transport.requests[0].url?.path == "/recipes")
        let body = try #require(transport.requests[0].httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["image_key"] == nil)
    }

    /// The local Recipe keeps its own bytes beside the address R2 now serves — ADR-0002.
    @Test("A share that lands files the Recipe under My Recipes with the URL it was given")
    func aLandedShareRecordsBoth() async {
        let (cookbook, _, _) = makeSharer()
        let recipe = photographedRecipe()

        await cookbook.share(recipe)

        #expect(recipe.remoteId == "new")
        #expect(recipe.imageURL == "https://pub.example/recipes/new/9f3.jpg")
        #expect(recipe.imageData != nil)
        #expect(cookbook.shareState(of: recipe) == nil)
        #expect(cookbook.segment(for: recipe) == .myRecipes)
    }

    @Test("A failure at any step leaves the Recipe Private and the failure on it",
          arguments: ShareStep.allCases)
    fileprivate func aFailedStepLeavesTheRecipePrivate(step: ShareStep) async {
        let (cookbook, _, _) = makeSharer(ShareFaults(step: step))
        let recipe = photographedRecipe()

        await cookbook.share(recipe)

        #expect(recipe.isPrivate)
        #expect(recipe.imageURL == nil)
        #expect(cookbook.shareState(of: recipe) == .failed)
    }

    @Test("A session the API has stopped accepting asks for a sign-in, not a retry")
    func anExpiredSessionAsksForASignIn() async {
        let (cookbook, _, _) = makeSharer(ShareFaults(step: .presign, status: 401))
        let recipe = photographedRecipe()

        await cookbook.share(recipe)

        #expect(recipe.isPrivate)
        #expect(cookbook.shareState(of: recipe) == .needsSignIn)
    }

    /// Without this the sheet is a dead end: the button would go on offering the sign-in the
    /// user has already been through, and the share could never be made again.
    @Test("Signing in again makes the refusal stale, so the share is offered afresh")
    func signingInAgainClearsTheRefusal() async {
        let (cookbook, _, auth) = makeSharer(ShareFaults(step: .presign, status: 401))
        let recipe = photographedRecipe()
        await cookbook.share(recipe)
        #expect(cookbook.shareState(of: recipe) == .needsSignIn)

        auth.setSession(
            token: "fresh",
            user: User(id: "u1", email: "cook@example.com", firstName: "Nicky", lastName: nil)
        )

        #expect(cookbook.shareState(of: recipe) == nil)
    }

    @Test("A second tap while the first share is in flight is the same share asked for twice")
    func aSecondTapIsDropped() async {
        let (cookbook, transport, _) = makeSharer()
        let recipe = photographedRecipe()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await cookbook.share(recipe) }
            group.addTask { await cookbook.share(recipe) }
        }

        #expect(transport.requests.count == 3)
    }

    @Test("A retry that lands clears the failure it was offered for")
    func aRetryClearsTheFailure() async {
        let faults = ShareFaults(step: .put)
        let (cookbook, _, _) = makeSharer(faults)
        let recipe = photographedRecipe()

        await cookbook.share(recipe)
        #expect(cookbook.shareState(of: recipe) == .failed)

        faults.step = nil
        await cookbook.share(recipe)

        #expect(cookbook.shareState(of: recipe) == nil)
        #expect(recipe.remoteId == "new")
    }

    /// The bytes are already within the contract, so the share hands R2 what SwiftData holds
    /// rather than putting every photo through a second encode.
    @Test("An encoded photo goes up as it is stored")
    func anEncodedPhotoGoesUpUntouched() async throws {
        let (cookbook, transport, _) = makeSharer()
        let recipe = photographedRecipe()
        let stored = recipe.imageData

        await cookbook.share(recipe)

        let put = try #require(transport.requests.first { $0.httpMethod == "PUT" })
        #expect(put.httpBody == stored)
        #expect(recipe.imageData == stored)
    }

    /// Photos picked before the encoder existed are full-resolution and survive an app
    /// update. Untouched, one of them is refused by the presign's size gate on every retry.
    @Test("A photo stored before the encoder existed is brought within the contract first")
    func aLegacyPhotoIsNormalizedBeforeItGoesUp() async throws {
        let (cookbook, transport, _) = makeSharer()
        let recipe = privateRecipe()
        recipe.imageData = jpeg(width: 2400, height: 1800)

        await cookbook.share(recipe)

        let put = try #require(transport.requests.first { $0.httpMethod == "PUT" })
        let uploaded = try #require(put.httpBody)
        let decoded = try #require(UIImage(data: uploaded))
        #expect(decoded.size.width * decoded.scale == RecipeImageEncoder.longestEdge)
        #expect(uploaded.count <= RecipeImageEncoder.ceiling)
        #expect(recipe.imageData == uploaded)
    }

    @Test("Bytes that are not a photo are shared as no photo rather than staged")
    func undecodableBytesAreNotUploaded() async {
        let (cookbook, transport, _) = makeSharer()
        let recipe = privateRecipe()
        recipe.imageData = Data(repeating: 0xFF, count: 512)

        await cookbook.share(recipe)

        #expect(transport.requests.count == 1)
        #expect(transport.requests[0].url?.path == "/recipes")
    }

    /// The share outlives its screen, so the account can change under it. Creating anyway
    /// publishes one user's Recipe as whoever happens to be signed in when the POST goes out.
    @Test("A share whose account changes mid-flight is abandoned rather than published")
    func anAccountChangeMidShareAbandonsIt() async {
        let faults = ShareFaults()
        let (cookbook, transport, auth) = makeSharer(faults)
        let recipe = photographedRecipe()
        faults.during = { step in
            guard step == .put else { return }
            auth.setSession(token: "someone-else", user: otherAccount())
        }

        await cookbook.share(recipe)

        #expect(!transport.requests.contains { $0.url?.path == "/recipes" })
        #expect(recipe.isPrivate)
        #expect(cookbook.shareState(of: recipe) == .failed)
    }

    /// The refusal belongs to the session the API turned down. Recording whichever session
    /// is current when the answer lands would pin it to an account that was never refused.
    @Test("A refusal is recorded against the session that was refused")
    func aRefusalBelongsToTheSessionThatWasRefused() async {
        let faults = ShareFaults(step: .presign, status: 401)
        let (cookbook, _, auth) = makeSharer(faults)
        let recipe = photographedRecipe()
        faults.during = { step in
            guard step == .presign else { return }
            auth.setSession(token: "fresh", user: otherAccount())
        }

        await cookbook.share(recipe)

        #expect(cookbook.shareState(of: recipe) == nil)
    }

    /// The Recipe stays editable while the upload runs, and the staged photo is already
    /// chosen by then: fields read afterwards would publish an edit against the old photo.
    @Test("A Recipe edited mid-share publishes what the user confirmed")
    func anEditMidShareDoesNotChangeWhatIsPublished() async throws {
        let faults = ShareFaults()
        let (cookbook, transport, _) = makeSharer(faults)
        let recipe = photographedRecipe()
        faults.during = { step in
            guard step == .put else { return }
            recipe.name = "Something Else"
            recipe.imageData = nil
        }

        await cookbook.share(recipe)

        let create = try #require(transport.requests.last)
        let body = try #require(create.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["name"] as? String == "Sunday Ragu")
        #expect(json["image_key"] as? String == "incoming/abc")
    }
}
