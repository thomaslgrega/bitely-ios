import Foundation

/// What the greeting bar reads, in every account state. The fallback chain ends at the
/// app's own name, so the bar keeps its shape rather than collapsing when signed out.
struct Greeting: Equatable {
    let salutation: String
    let name: String?
}

extension Greeting {
    init(user: User?) {
        if let name = Self.name(of: user) {
            self.init(salutation: "Welcome,", name: name)
        } else {
            self.init(salutation: "Welcome to Bitely", name: nil)
        }
    }

    private static func name(of user: User?) -> String? {
        guard let user else { return nil }
        // `prefix(while:)` rather than splitting on "@": splitting drops the empty piece,
        // so "@example.com" would greet the user by their mail host.
        let localPart = user.email.map { String($0.prefix { $0 != "@" }) }
        return usable(user.firstName) ?? usable(localPart)
    }

    private static func usable(_ candidate: String?) -> String? {
        let value = candidate?.trimmingCharacters(in: .whitespaces)
        return value?.isEmpty == false ? value : nil
    }
}
