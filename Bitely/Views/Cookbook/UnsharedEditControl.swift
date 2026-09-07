import Foundation

/// What a Recipe's detail screen says when the device is ahead of the corpus, and what one
/// tap does about it. `ShareControl`'s counterpart: Share is withheld once a Recipe is
/// Shared, and this is withheld until it is, so the screen draws one or neither.
///
/// An edit that has not been attempted and one whose push failed read the same, because to
/// the user they are one situation — the changes are not shared and a tap sends them.
struct UnsharedEditControl: Equatable {
    enum Tap: Equatable {
        case push
        case presentAuth
    }

    let isShared: Bool
    let hasUnsharedEdit: Bool
    let editState: ShareState?

    init(isShared: Bool, hasUnsharedEdit: Bool, editState: ShareState? = nil) {
        self.isShared = isShared
        self.hasUnsharedEdit = hasUnsharedEdit
        self.editState = editState
    }

    var isOffered: Bool { isShared && hasUnsharedEdit }

    var label: String {
        switch editState {
        case .inFlight: "Sharing changes…"
        case .needsSignIn: "Sign in again to share changes"
        case .failed, nil: "Changes not shared — tap to retry"
        }
    }

    var isEnabled: Bool { editState != .inFlight }

    var tap: Tap { editState == .needsSignIn ? .presentAuth : .push }
}

extension UnsharedEditControl {
    init(recipe: Recipe, editState: ShareState? = nil) {
        self.init(
            isShared: !recipe.isPrivate,
            hasUnsharedEdit: recipe.hasUnsharedEdit,
            editState: editState
        )
    }
}
