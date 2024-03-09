import Atomics

///
public struct OnceState: Sendable {

    /// Initialises an instance of the `OnceState` type
    public init() {
        self.done = ManagedAtomic(false)
    }

    private let done: ManagedAtomic<Bool>

    /// Runs only once per instance of `OnceState` type no matter how many these times it was called
    /// - Parameter body: a closure is to be exexcuted
    public func runOnce(body: @escaping () throws -> Void) rethrows {
        guard
            self.done.compareExchange(
                expected: false, desired: true, ordering: .acquiringAndReleasing
            )
            .exchanged
        else {
            return
        }
        return try body()
    }

    /// Indicated if this instance have executed it's `runOnce` mehod
    public var hasExecuted: Bool {
        self.done.load(ordering: .acquiring)
    }
}
