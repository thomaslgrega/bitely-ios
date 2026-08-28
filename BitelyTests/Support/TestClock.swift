import Foundation
@testable import Bitely

/// A `Clock` whose time only moves when a test says so, so a debounce is exercised by
/// advancing past it rather than by sleeping through it. A real sleep is slow and answers
/// differently on a loaded machine, which the parallel suite makes likely.
///
/// Each test builds its own, so nothing here is shared between tests.
final class TestClock: Clock, @unchecked Sendable {
    struct Instant: InstantProtocol {
        var offset: Duration

        func advanced(by duration: Duration) -> Instant { Instant(offset: offset + duration) }
        func duration(to other: Instant) -> Duration { other.offset - offset }
        static func < (lhs: Instant, rhs: Instant) -> Bool { lhs.offset < rhs.offset }
    }

    private struct Sleeper {
        let deadline: Instant
        let continuation: CheckedContinuation<Void, Error>
    }

    /// How many times `advance(by:)` offers the executor a turn while it waits for the
    /// work the caller just started to reach its sleep. Yielding costs nothing when the
    /// work is already there, and nothing sleeps at all in some tests.
    private static let yieldsAwaitingSleep = 100

    var minimumResolution: Duration { .zero }

    private let lock = NSLock()
    private var current = Instant(offset: .zero)
    private var sleepers: [UUID: Sleeper] = [:]
    private var cancelled: Set<UUID> = []

    var now: Instant { lock.withLock { current } }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                lock.withLock {
                    if cancelled.contains(id) {
                        continuation.resume(throwing: CancellationError())
                    } else if current >= deadline {
                        continuation.resume()
                    } else {
                        sleepers[id] = Sleeper(deadline: deadline, continuation: continuation)
                    }
                }
            }
        } onCancel: {
            let sleeper: Sleeper? = lock.withLock {
                cancelled.insert(id)
                return sleepers.removeValue(forKey: id)
            }
            sleeper?.continuation.resume(throwing: CancellationError())
        }
    }

    /// Moves time forward and wakes everything now due.
    ///
    /// It yields until something is asleep, because a caller advances the clock right
    /// after starting the work that sleeps, and that work takes its deadline from the time
    /// it finds — so moving first would put the deadline out of reach. Nothing asleep
    /// after the yields is a test advancing past work it has cancelled, not a wait.
    func advance(by duration: Duration) async {
        for _ in 0..<Self.yieldsAwaitingSleep where isSleeping == false {
            await Task.yield()
        }

        let due: [Sleeper] = lock.withLock {
            current = current.advanced(by: duration)
            let due = sleepers.filter { $0.value.deadline <= current }
            due.keys.forEach { sleepers.removeValue(forKey: $0) }
            return Array(due.values)
        }
        due.forEach { $0.continuation.resume() }
        await Task.yield()
    }

    private var isSleeping: Bool { lock.withLock { !sleepers.isEmpty } }
}
