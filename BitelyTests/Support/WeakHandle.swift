import Foundation

/// A weak reference a test can still read after the strong one is gone, for asserting that
/// something was released rather than kept alive by work it started.
final class WeakHandle<Object: AnyObject> {
    weak var value: Object?

    init(_ value: Object) {
        self.value = value
    }
}
