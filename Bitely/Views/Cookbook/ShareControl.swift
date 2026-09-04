import Foundation

extension Recipe {
    /// Written here and never shared. The only kind of Recipe the Share action is offered
    /// on, and the only kind whose remote id is still absent.
    var isPrivate: Bool { remoteId == nil }
}

/// Whether a Recipe's detail screen offers Share, what it reads, and what one tap does.
/// Signed out it presents auth at the moment of sharing, where the intent is unambiguous and
/// there is no half-filled form to lose — docs/design/app-flow.md, Cookbook.
struct ShareControl: Equatable {
    enum Tap: Equatable {
        case confirmShare
        case share
        case presentAuth
    }

    let isPrivate: Bool
    let isAuthenticated: Bool
    let shareState: ShareState?

    init(isPrivate: Bool, isAuthenticated: Bool, shareState: ShareState? = nil) {
        self.isPrivate = isPrivate
        self.isAuthenticated = isAuthenticated
        self.shareState = shareState
    }

    /// A Saved Recipe is someone else's work and cannot be re-shared under this user's
    /// name; one already shared has nowhere to go.
    var isOffered: Bool { isPrivate }

    /// The button is where a share reports itself: this app has no toast or banner, and a
    /// share against a cold instance takes tens of seconds — ADR-0002.
    var label: String {
        switch shareState {
        case nil: "Share"
        case .inFlight: "Sharing…"
        case .failed: "Share failed — tap to retry"
        case .needsSignIn: "Sign in again to share"
        }
    }

    var isEnabled: Bool { shareState != .inFlight }

    /// A retry skips the confirmation the failed attempt already collected.
    var tap: Tap {
        switch shareState {
        case .needsSignIn: .presentAuth
        case .failed: .share
        default: isAuthenticated ? .confirmShare : .presentAuth
        }
    }
}

extension ShareControl {
    init(recipe: Recipe, isAuthenticated: Bool, shareState: ShareState? = nil) {
        self.init(
            isPrivate: recipe.isPrivate,
            isAuthenticated: isAuthenticated,
            shareState: shareState
        )
    }
}
