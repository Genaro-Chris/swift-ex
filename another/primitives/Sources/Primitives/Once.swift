import Atomics

///
public enum Once {

    private static let done: ManagedAtomic<Bool> = ManagedAtomic(false)

    /// Runs only once per process no matter how many these times it was called
    /// - Parameter body: a closure is to be exexcuted
    public static func runOnce(_ body: @escaping () throws -> Void) rethrows {
        guard
            Self.done.compareExchange(
                expected: false, desired: true, ordering: .acquiringAndReleasing
            )
            .exchanged
        else {
            return
        }
        return try body()
    }
}