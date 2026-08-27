import Foundation

enum AuthMode: Equatable {
    case logIn
    case createAccount
}

/// What the auth sheet holds while it is being filled in: the mode, the two fields, and
/// whether a request is in flight.
struct AuthForm: Equatable {
    var mode: AuthMode = .logIn
    var email = ""
    var password = ""
    var isLoading = false
    /// Deliberately vague, and never says which of the two was wrong: an account's
    /// existence is not something a signed-out caller gets to probe for.
    var errorMessage: String?

    var title: String {
        switch mode {
        case .logIn: "Log In"
        case .createAccount: "Create Account"
        }
    }

    var switchTitle: String {
        switch mode {
        case .logIn: "New here? Create Account"
        case .createAccount: "Already have an account? Log In"
        }
    }

    var canSubmit: Bool {
        !isLoading && !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    mutating func switchMode() {
        mode = mode == .logIn ? .createAccount : .logIn
        errorMessage = nil
    }
}
