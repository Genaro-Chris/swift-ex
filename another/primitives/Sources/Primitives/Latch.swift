import Atomics
import Foundation

///
public struct Latch: Sendable {

    private let blockedThreadsCount: ManagedAtomic<UInt>
    private let latch: ManagedAtomic<Bool>

    /// Initialises an instance of the `Latch` type
    /// - Parameter count:
    public init?(count: UInt) {
        guard count >= 1 else {
            return nil
        }
        self.latch = ManagedAtomic(false)
        self.blockedThreadsCount = ManagedAtomic(count)
    }

    /// Decrements the count of the `Latch` instance and blocks the current thread until the instance's count drops to zero
    public func decrementAndWait() {
        guard self.blockedThreadsCount.load(ordering: .acquiring) != 0 else {
            return
        }
        guard
            self.blockedThreadsCount.wrappingDecrementThenLoad(
                ordering: .acquiringAndReleasing) != 0
        else {
            self.latch.store(true, ordering: .releasing)
            return
        }
        while !self.latch.load(ordering: .acquiring) {}

    }

    /// Decrements the count of an `Latch` instance
    /// without blocking the current thread
    public func decrementAlone() {
        guard self.blockedThreadsCount.load(ordering: .acquiring) != 0 else { return }
        if self.blockedThreadsCount.wrappingDecrementThenLoad(
            ordering: .acquiringAndReleasing) == 0
        {
            self.latch.store(true, ordering: .releasing)
        }
    }

    /// Blocks the current thread until the instance's count drops to zero
    ///
    /// Warning - This function will deadlock if ``decrementAndWait`` method is called more or less than the count passed to the initializer
    public func waitForAll() {
        while !self.latch.load(ordering: .acquiring) {}
    }

}
