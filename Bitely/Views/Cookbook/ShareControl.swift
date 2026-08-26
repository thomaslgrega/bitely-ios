import Foundation

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
