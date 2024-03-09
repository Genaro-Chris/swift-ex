import Atomics
import Foundation

///
public struct Lock: Sendable {

    private let lock: ManagedAtomic<Bool>

    /// Initialises an instance of the `Lock` type
    public init() {
        self.lock = ManagedAtomic(true)
    }

    ///
    /// - Parameter body: closure to be executed while being protected by the lock
    /// - Returns: return value from the body closure
    @discardableResult
    public func whileLocked<T>(_ body: () throws -> T) rethrows -> T {
        while !self.lock.weakCompareExchange(
            expected: true, desired: false, ordering: .acquiringAndReleasing
        )
        .exchanged {
            Thread.sleep(forTimeInterval: 0.0000000000000000001)
        }
        defer {
            self.lock.store(true, ordering: .releasing)
        }
        return try body()
    }
}
