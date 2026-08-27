import Testing
@testable import Bitely

@Suite("AuthForm")
struct AuthFormTests {

    @Test("logging in and creating an account read differently everywhere they are shown")
    func copy() {
        var form = AuthForm()

        #expect(form.mode == .logIn)
        #expect(form.title == "Log In")
        #expect(form.switchTitle == "New here? Create Account")

        form.switchMode()

        #expect(form.mode == .createAccount)
        #expect(form.title == "Create Account")
        #expect(form.switchTitle == "Already have an account? Log In")
    }

    @Test("switching modes clears the error the other mode produced")
    func switchingClearsError() {
        var form = AuthForm()
        form.errorMessage = "Failed. Check your email/password and try again."

        form.switchMode()

        #expect(form.errorMessage == nil)
    }

    @Test(
        "submission needs both fields and no request in flight",
        arguments: [
            ("a@example.com", "hunter2", false, true),
            ("", "hunter2", false, false),
            ("a@example.com", "", false, false),
            ("   ", "hunter2", false, false),
            ("a@example.com", "hunter2", true, false),
        ]
    )
    func canSubmit(email: String, password: String, isLoading: Bool, expected: Bool) {
        var form = AuthForm()
        form.email = email
        form.password = password
        form.isLoading = isLoading

        #expect(form.canSubmit == expected)
    }
}
