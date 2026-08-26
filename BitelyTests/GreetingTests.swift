import Foundation
import Testing
@testable import Bitely

private func user(firstName: String? = nil, email: String? = nil) -> User {
    User(id: "u1", email: email, firstName: firstName, lastName: nil)
}

@Suite("Greeting")
struct GreetingTests {

    @Test("Signed out, the bar names the app rather than the user")
    func signedOut() {
        #expect(Greeting(user: nil) == Greeting(salutation: "Welcome to Bitely", name: nil))
    }

    @Test("A first name is used when there is one")
    func firstName() {
        #expect(Greeting(user: user(firstName: "Nicky", email: "nicky@example.com"))
                == Greeting(salutation: "Welcome,", name: "Nicky"))
    }

    @Test("Without a first name, the email's local part stands in")
    func emailLocalPart() {
        #expect(Greeting(user: user(email: "nicky.m@example.com"))
                == Greeting(salutation: "Welcome,", name: "nicky.m"))
    }

    @Test("A name of nothing but whitespace falls through to the next source")
    func blankFirstName() {
        #expect(Greeting(user: user(firstName: "   ", email: "nicky@example.com"))
                == Greeting(salutation: "Welcome,", name: "nicky"))
    }

    @Test("An account with neither a name nor an email reads the same as signed out")
    func noNameAndNoEmail() {
        #expect(Greeting(user: user()) == Greeting(salutation: "Welcome to Bitely", name: nil))
    }

    @Test("An email with no local part is no name at all", arguments: ["@example.com", "   "])
    func unusableEmail(email: String) {
        #expect(Greeting(user: user(email: email)).name == nil)
    }
}
