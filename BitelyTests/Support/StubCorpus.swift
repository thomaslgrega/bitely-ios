import Foundation
@testable import Bitely

/// A `CorpusMatching` that answers from a canned result and records the Pantry
/// Items it was asked about.
///
/// Each test builds its own instance, so tests stay independent under Swift
/// Testing's parallel execution.
final class StubCorpus: CorpusMatching, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [[String]] = []
    private let result: Result<[RecipeMatch], Error>

    /// Runs before the answer is handed back, so a test can change the Pantry
    /// while the corpus is still working.
    var duringSearch: (() -> Void)?

    init(_ result: Result<[RecipeMatch], Error>) {
        self.result = result
    }

    static func matching(_ matches: [RecipeMatch]) -> StubCorpus {
        StubCorpus(.success(matches))
    }

    /// Fails every search, as a device with no network does.
    static func unreachable(_ error: Error = URLError(.notConnectedToInternet)) -> StubCorpus {
        StubCorpus(.failure(error))
    }

    /// The Pantry Items of the most recent search, verbatim.
    var lastPantryItems: [String]? {
        lock.withLock { recorded.last }
    }

    func matchCorpus(pantryItems: [String]) async throws -> [RecipeMatch] {
        lock.withLock { recorded.append(pantryItems) }
        duringSearch?()
        return try result.get()
    }
}
