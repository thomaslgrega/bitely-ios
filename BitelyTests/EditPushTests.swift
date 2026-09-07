import Foundation
import SwiftData
import Testing
import UIKit
@testable import Bitely

private enum PushLeg: String, CaseIterable {
    case presign, bytes, image, text
}

/// Which leg of a push fails, mutable so one test can let a retry through.
private final class PushFaults: @unchecked Sendable {
    var leg: PushLeg?
    var status: Int
    /// Runs as each leg is answered, so a test can change the world mid-push.
    var during: ((PushLeg) -> Void)?

    init(leg: PushLeg? = nil, status: Int = 500) {
        self.leg = leg
        self.status = status
    }
}

private let authorshipBody = #"""
[{"id":"mine","name":"Short Rib","category":"Beef","image_url":null,
  "calories":null,"total_cook_time":null}]
"""#

/// Answers every leg a push can make — authorship, the presign, R2's PUT, the image
/// sub-resource and the recipe write — from one stub, so a test reads the requests in the
/// order the push made them.
private func pushTransport(_ faults: PushFaults) -> StubTransport {
    StubTransport { request in
        let url = request.url!
        let method = request.httpMethod ?? "GET"
        var body = ""
        var code = 200

        switch (url.host, url.path, method) {
        case (_, "/me/recipes", _):
            // Authorship is the account's, so a second account authored none of it.
            let isOwner = request.value(forHTTPHeaderField: "Authorization") == "Bearer token"
            body = isOwner ? authorshipBody : "[]"
        case (_, "/recipes/images", _):
            faults.during?(.presign)
            if faults.leg == .presign {
                code = faults.status
            } else {
                body = #"{"upload_url":"https://r2.example/incoming/abc?sig=1","key":"incoming/abc"}"#
            }
        case ("r2.example", _, _):
            faults.during?(.bytes)
            if faults.leg == .bytes { code = faults.status }
        case (_, let path, _) where path.hasSuffix("/image"):
            faults.during?(.image)
            if faults.leg == .image {
                code = faults.status
            } else if method == "DELETE" {
                code = 204
            } else {
                body = #"{"image_url":"https://pub.example/recipes/mine/7c1.jpg"}"#
            }
        default:
            faults.during?(.text)
            code = faults.leg == .text ? faults.status : 204
        }

        let response = HTTPURLResponse(
            url: url, statusCode: code, httpVersion: "HTTP/1.1", headerFields: nil
        )!
        return (Data(body.utf8), response)
    }
}

@MainActor
private func makePusher(
    _ faults: PushFaults = PushFaults(),
    signedIn: Bool = true
) -> (Cookbook, StubTransport, AuthStore) {
    let transport = pushTransport(faults)
    let auth = AuthStore(defaults: makeIsolatedDefaults())
    if signedIn {
        auth.setSession(
            token: "token",
            user: User(id: "u1", email: "cook@example.com", firstName: "Nicky", lastName: nil)
        )
    }
    let service = RecipeService(
        api: APIClient(authStore: auth, transport: transport),
        uploads: PresignedUploader(transport: transport)
    )
    return (Cookbook(service: service, authStore: auth), transport, auth)
}

@MainActor
private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: Recipe.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private func jpeg(width: CGFloat, height: CGFloat) -> Data {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        .image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        }
    return image.jpegData(compressionQuality: 0.8)!
}

/// A Shared Recipe this user authored, which is the only kind an edit pushes.
private func authored() -> Recipe {
    Recipe(
        remoteId: "mine",
        name: "Short Rib",
        category: .beef,
        instructions: "Braise it.",
        ingredients: [Ingredient(name: "short rib", measurement: "1kg")],
        calories: 800,
        totalCookTime: 240
    )
}

private func saved() -> Recipe { Recipe(remoteId: "theirs", name: "Shakshuka", category: .breakfast) }
private func unshared() -> Recipe { Recipe(name: "Sunday Ragu", category: .pasta) }

/// Everything a push made, with the authorship fetch that precedes it taken out.
private func pushRequests(_ transport: StubTransport) -> [URLRequest] {
    transport.requests.filter { $0.url?.path != "/me/recipes" }
}

private func json(_ request: URLRequest) throws -> [String: Any] {
    let body = try #require(request.httpBody)
    return try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
}

@MainActor
@Suite("Pushing an edit to the corpus")
struct EditPushTests {

    @Test("An edit to a Private Recipe or a Saved Recipe reaches the API for nothing",
          arguments: [true, false])
    func onlyAuthoredSharedRecipesPush(isPrivate: Bool) async throws {
        let (cookbook, transport, _) = makePusher()
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = isPrivate ? unshared() : saved()

        cookbook.commit(recipe, photoEdited: true, into: context)
        await cookbook.push(recipe)

        #expect(pushRequests(transport).isEmpty)
        #expect(recipe.hasUnsharedEdit == false)
    }

    @Test("Editing an authored Shared Recipe writes the whole Recipe back, carrying no image")
    func theTextLegCarriesTheWholeRecipe() async throws {
        let (cookbook, transport, _) = makePusher()
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()

        cookbook.commit(recipe, photoEdited: false, into: context)
        await cookbook.push(recipe)

        let requests = pushRequests(transport)
        #expect(requests.count == 1)
        let write = try #require(requests.first)
        #expect(write.httpMethod == "PUT")
        #expect(write.url?.path == "/recipes/mine")
        #expect(write.value(forHTTPHeaderField: "Authorization") == "Bearer token")

        let body = try json(write)
        #expect(body["name"] as? String == "Short Rib")
        #expect(body["category"] as? String == "Beef")
        #expect(body["instructions"] as? String == "Braise it.")
        #expect(body["calories"] as? Int == 800)
        #expect(body["total_cook_time"] as? Int == 240)
        #expect(body["image_key"] == nil)
        #expect(body["image_url"] == nil)

        let ingredients = try #require(body["ingredients"] as? [[String: Any]])
        #expect(ingredients.count == 1)
        #expect(ingredients[0]["id"] as? String == recipe.ingredients[0].id.uuidString)
        #expect(ingredients[0]["name"] as? String == "short rib")
        #expect(ingredients[0]["measurement"] as? String == "1kg")
        #expect(recipe.hasUnsharedEdit == false)
    }

    @Test("A changed photo goes up before the Recipe write, and the new URL is kept")
    func aChangedPhotoIsWrittenFirst() async throws {
        let (cookbook, transport, _) = makePusher()
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        recipe.imageData = jpeg(width: 400, height: 300)

        cookbook.commit(recipe, photoEdited: true, into: context)
        await cookbook.push(recipe)

        let requests = pushRequests(transport)
        #expect(requests.count == 4)
        #expect(requests[0].url?.path == "/recipes/images")
        #expect(requests[1].url?.host == "r2.example")
        #expect(requests[2].url?.path == "/recipes/mine/image")
        #expect(requests[2].httpMethod == "PUT")
        #expect(try json(requests[2])["image_key"] as? String == "incoming/abc")
        #expect(requests[3].url?.path == "/recipes/mine")

        #expect(recipe.imageURL == "https://pub.example/recipes/mine/7c1.jpg")
        #expect(recipe.hasUnsharedEdit == false)
    }

    @Test("Removing the photo deletes the sub-resource, staging nothing")
    func removingThePhotoDeletesIt() async throws {
        let (cookbook, transport, _) = makePusher()
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        recipe.imageURL = "https://pub.example/recipes/mine/old.jpg"

        cookbook.commit(recipe, photoEdited: true, into: context)
        await cookbook.push(recipe)

        let requests = pushRequests(transport)
        #expect(requests.count == 2)
        #expect(requests[0].httpMethod == "DELETE")
        #expect(requests[0].url?.path == "/recipes/mine/image")
        #expect(requests[1].url?.path == "/recipes/mine")
        #expect(recipe.imageURL == nil)
    }

    @Test("A save that left the photo alone touches neither image endpoint")
    func anUntouchedPhotoIsNotRewritten() async throws {
        let (cookbook, transport, _) = makePusher()
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        recipe.imageData = jpeg(width: 400, height: 300)
        recipe.imageURL = "https://pub.example/recipes/mine/old.jpg"

        cookbook.commit(recipe, photoEdited: false, into: context)
        await cookbook.push(recipe)

        #expect(pushRequests(transport).count == 1)
        #expect(recipe.imageURL == "https://pub.example/recipes/mine/old.jpg")
    }

    @Test("A failure on the image leg abandons the save, leaving both legs to retry",
          arguments: [PushLeg.presign, .bytes, .image])
    fileprivate func aFailedImageLegStopsTheSave(leg: PushLeg) async throws {
        let (cookbook, transport, _) = makePusher(PushFaults(leg: leg))
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        recipe.imageData = jpeg(width: 400, height: 300)

        cookbook.commit(recipe, photoEdited: true, into: context)
        await cookbook.push(recipe)

        #expect(pushRequests(transport).contains { $0.url?.path == "/recipes/mine" } == false)
        #expect(recipe.unsharedImageEdit)
        #expect(recipe.unsharedTextEdit)
        #expect(cookbook.editState(of: recipe) == .failed)
    }

    @Test("A text leg that fails after the photo landed leaves only itself to retry")
    func aFailedTextLegDoesNotReuploadThePhoto() async throws {
        let faults = PushFaults(leg: .text)
        let (cookbook, transport, _) = makePusher(faults)
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        recipe.imageData = jpeg(width: 400, height: 300)

        cookbook.commit(recipe, photoEdited: true, into: context)
        await cookbook.push(recipe)

        #expect(recipe.unsharedImageEdit == false)
        #expect(recipe.unsharedTextEdit)
        #expect(cookbook.editState(of: recipe) == .failed)

        faults.leg = nil
        let before = pushRequests(transport).count
        await cookbook.push(recipe)

        let retry = Array(pushRequests(transport).dropFirst(before))
        #expect(retry.count == 1)
        #expect(retry[0].url?.path == "/recipes/mine")
        #expect(recipe.hasUnsharedEdit == false)
        #expect(cookbook.editState(of: recipe) == nil)
    }

    /// A push makes the corpus match the device, so a retry carries the newest edit rather
    /// than replaying the one that failed — ADR-0003.
    @Test("A retry sends the Recipe as it stands, not as it was when the push failed")
    func aRetrySendsTheCurrentRecipe() async throws {
        let faults = PushFaults(leg: .text)
        let (cookbook, transport, _) = makePusher(faults)
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()

        cookbook.commit(recipe, photoEdited: false, into: context)
        await cookbook.push(recipe)

        recipe.name = "Braised Short Rib"
        faults.leg = nil
        await cookbook.push(recipe)

        let write = try #require(pushRequests(transport).last)
        #expect(try json(write)["name"] as? String == "Braised Short Rib")
    }

    @Test("An edit made while a push is in flight is pushed after it, without another tap")
    func anEditMidPushIsPushedAfterIt() async throws {
        let faults = PushFaults()
        let (cookbook, transport, _) = makePusher(faults)
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        cookbook.commit(recipe, photoEdited: false, into: context)

        var edited = false
        faults.during = { leg in
            guard leg == .text, !edited else { return }
            edited = true
            recipe.name = "Braised Short Rib"
            recipe.editGeneration += 1
        }

        await cookbook.push(recipe)

        let writes = pushRequests(transport)
        #expect(writes.count == 2)
        let second = try #require(writes.dropFirst().first)
        #expect(try json(second)["name"] as? String == "Braised Short Rib")
        #expect(recipe.hasUnsharedEdit == false)
        #expect(cookbook.editState(of: recipe) == nil)
    }

    @Test("A session the API has stopped accepting asks for a sign-in, not a retry",
          arguments: [PushLeg.presign, .text])
    fileprivate func anExpiredSessionAsksForASignIn(leg: PushLeg) async throws {
        let (cookbook, _, _) = makePusher(PushFaults(leg: leg, status: 401))
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        recipe.imageData = jpeg(width: 400, height: 300)

        cookbook.commit(recipe, photoEdited: true, into: context)
        await cookbook.push(recipe)

        #expect(cookbook.editState(of: recipe) == .needsSignIn)
        #expect(recipe.unsharedTextEdit)
    }

    /// The flag is what survives a kill, so clearing it before the response landed would let
    /// an app killed mid-push forget an edit the corpus never received — ADR-0003.
    @Test("The pending flag stands until the response that lands its leg has arrived")
    func theFlagOutlivesTheRequestItIsWaitingOn() async throws {
        let faults = PushFaults()
        let (cookbook, _, _) = makePusher(faults)
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        cookbook.commit(recipe, photoEdited: false, into: context)

        var pendingWhileInFlight: Bool?
        faults.during = { leg in
            guard leg == .text else { return }
            pendingWhileInFlight = recipe.unsharedTextEdit
        }

        await cookbook.push(recipe)

        #expect(pendingWhileInFlight == true)
        #expect(recipe.unsharedTextEdit == false)
    }

    /// Issue #57: the branch is authorship, and a Saved Recipe stays local forever. A pending
    /// edit is the account's that made it, so it is neither sent nor offered under another.
    @Test("An edit left pending by one account is not sent or offered under another")
    func aPendingEditDoesNotFollowTheAccount() async throws {
        let faults = PushFaults(leg: .text)
        let (cookbook, transport, auth) = makePusher(faults)
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        cookbook.commit(recipe, photoEdited: false, into: context)
        await cookbook.push(recipe)
        #expect(recipe.unsharedTextEdit)

        faults.leg = nil
        auth.setSession(
            token: "someone-else",
            user: User(id: "u2", email: "sam@example.com", firstName: "Sam", lastName: nil)
        )
        await cookbook.loadAuthorship()
        let before = pushRequests(transport).count

        await cookbook.push(recipe)

        #expect(pushRequests(transport).count == before)
        #expect(recipe.unsharedTextEdit)
        let control = UnsharedEditControl(
            isAuthored: cookbook.propagatesEdits(to: recipe),
            hasUnsharedEdit: recipe.hasUnsharedEdit
        )
        #expect(control.isOffered == false)
    }

    /// The detail screen pushes on every appearance, so without this a refused Recipe would
    /// talk over the sheet it is offering with a doomed request each time it is opened.
    @Test("A Recipe refused for this session is left alone until the account changes")
    func aRefusedPushIsNotRefiredOnAppearance() async throws {
        let (cookbook, transport, _) = makePusher(PushFaults(leg: .text, status: 401))
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()

        cookbook.commit(recipe, photoEdited: false, into: context)
        await cookbook.push(recipe)
        let refused = pushRequests(transport).count

        await cookbook.push(recipe)

        #expect(pushRequests(transport).count == refused)
        #expect(cookbook.editState(of: recipe) == .needsSignIn)
    }

    /// The push outlives its screen, so the account can change while it runs — ADR-0002.
    @Test("A push whose account changes mid-flight is abandoned rather than written")
    func anAccountChangeMidPushAbandonsIt() async throws {
        let faults = PushFaults()
        let (cookbook, transport, auth) = makePusher(faults)
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        recipe.imageData = jpeg(width: 400, height: 300)
        cookbook.commit(recipe, photoEdited: true, into: context)

        faults.during = { leg in
            guard leg == .image else { return }
            auth.setSession(
                token: "someone-else",
                user: User(id: "u2", email: "sam@example.com", firstName: "Sam", lastName: nil)
            )
        }

        await cookbook.push(recipe)

        #expect(pushRequests(transport).contains { $0.url?.path == "/recipes/mine" } == false)
        #expect(recipe.unsharedTextEdit)
        #expect(cookbook.editState(of: recipe) == .failed)
    }

    @Test("Signing in again makes the refusal stale, so the push is offered afresh")
    func signingInAgainClearsTheRefusal() async throws {
        let (cookbook, _, auth) = makePusher(PushFaults(leg: .text, status: 401))
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()

        cookbook.commit(recipe, photoEdited: false, into: context)
        await cookbook.push(recipe)
        #expect(cookbook.editState(of: recipe) == .needsSignIn)

        auth.setSession(
            token: "fresh",
            user: User(id: "u1", email: "cook@example.com", firstName: "Nicky", lastName: nil)
        )

        #expect(cookbook.editState(of: recipe) == nil)
    }

    /// Signed out the device cannot tell this user's own Shared Recipes from the ones they
    /// saved, so an edit records nothing rather than flagging someone else's work — ADR-0003.
    @Test("Signed out, an edit to a Shared Recipe stays local and is not recorded as pending")
    func signedOutAnEditIsNotRecorded() async throws {
        let (cookbook, transport, _) = makePusher(signedIn: false)
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()

        cookbook.commit(recipe, photoEdited: true, into: context)
        await cookbook.push(recipe)

        #expect(pushRequests(transport).isEmpty)
        #expect(recipe.hasUnsharedEdit == false)
    }

    @Test("Authorship not yet answered, an edit records nothing rather than guessing")
    func unresolvedAuthorshipRecordsNothing() async throws {
        let (cookbook, transport, _) = makePusher()
        let context = try makeContext()
        let recipe = authored()

        cookbook.commit(recipe, photoEdited: true, into: context)

        #expect(cookbook.hasResolvedAuthorship == false)
        #expect(recipe.hasUnsharedEdit == false)
        #expect(pushRequests(transport).isEmpty)
    }

    /// The flags are on the Recipe rather than in the store, so a kill mid-push leaves the
    /// drift recorded where the next launch can find it — ADR-0003.
    @Test("An Unshared Edit survives the Cookbook that made it")
    func anUnsharedEditOutlivesTheSession() async throws {
        let (cookbook, _, _) = makePusher(PushFaults(leg: .text))
        await cookbook.loadAuthorship()
        let context = try makeContext()
        let recipe = authored()
        cookbook.commit(recipe, photoEdited: false, into: context)
        await cookbook.push(recipe)
        try context.save()

        let (relaunched, transport, _) = makePusher()
        await relaunched.loadAuthorship()
        let stored = try #require(try context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(stored.hasUnsharedEdit)

        await relaunched.push(stored)

        #expect(pushRequests(transport).count == 1)
        #expect(stored.hasUnsharedEdit == false)
    }
}

@MainActor
@Suite("The Unshared Edit control")
struct UnsharedEditControlTests {

    @Test("It reports on an authored Shared Recipe with an Unshared Edit and on nothing else",
          arguments: [
            (isAuthored: true, hasEdit: true, offered: true),
            (isAuthored: true, hasEdit: false, offered: false),
            (isAuthored: false, hasEdit: true, offered: false),
            (isAuthored: false, hasEdit: false, offered: false)
          ])
    func itIsOfferedOnlyWhereThereIsDrift(isAuthored: Bool, hasEdit: Bool, offered: Bool) {
        let control = UnsharedEditControl(isAuthored: isAuthored, hasUnsharedEdit: hasEdit)

        #expect(control.isOffered == offered)
    }

    @Test("A push in flight says so and cannot be asked for again")
    func aPushInFlightSaysSo() {
        let control = UnsharedEditControl(isAuthored: true, hasUnsharedEdit: true, editState: .inFlight)

        #expect(control.label == "Sharing changes…")
        #expect(control.isEnabled == false)
    }

    @Test("A failed push offers the retry directly")
    func aFailedPushOffersARetry() {
        let control = UnsharedEditControl(isAuthored: true, hasUnsharedEdit: true, editState: .failed)

        #expect(control.label == "Changes not shared — tap to retry")
        #expect(control.isEnabled)
        #expect(control.tap == .push)
    }

    /// Before any attempt has been made — an edit saved with no connection — the control says
    /// the same thing, because to the user those are one situation.
    @Test("An edit that has not been attempted reads as one to retry")
    func anUnattemptedEditReadsTheSame() {
        let control = UnsharedEditControl(isAuthored: true, hasUnsharedEdit: true)

        #expect(control.label == "Changes not shared — tap to retry")
        #expect(control.tap == .push)
    }

    @Test("A push refused for the session offers auth rather than a retry")
    func aRefusedPushOffersAuth() {
        let control = UnsharedEditControl(isAuthored: true, hasUnsharedEdit: true, editState: .needsSignIn)

        #expect(control.label == "Sign in again to share changes")
        #expect(control.tap == .presentAuth)
    }

    /// The detail screen draws one control or the other, never both: Share is withheld once a
    /// Recipe is Shared, and this one is withheld until it is.
    @Test("The two controls never appear together")
    func theTwoControlsDoNotOverlap() {
        let onShared = (
            share: ShareControl(isPrivate: false, isAuthenticated: true),
            edits: UnsharedEditControl(isAuthored: true, hasUnsharedEdit: true)
        )
        let onPrivate = (
            share: ShareControl(isPrivate: true, isAuthenticated: true),
            edits: UnsharedEditControl(isAuthored: false, hasUnsharedEdit: true)
        )

        #expect(onShared.share.isOffered == false)
        #expect(onShared.edits.isOffered)
        #expect(onPrivate.share.isOffered)
        #expect(onPrivate.edits.isOffered == false)
    }
}
