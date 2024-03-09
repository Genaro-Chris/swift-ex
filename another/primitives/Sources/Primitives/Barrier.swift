import Atomics
import Foundation

///
public struct Barrier: Sendable {

    private let blockedThreadsCount: ManagedAtomic<UInt>
    private let barrier: ManagedAtomic<Bool>
    private let threadCount: UInt

    /// Initialises an instance of the `Barrier` type
    /// - Parameter count:
    public init?(count: UInt) {
        guard count >= 1 else {
            return nil
        }
        self.barrier = ManagedAtomic(false)
        self.threadCount = count
        self.blockedThreadsCount = ManagedAtomic(count)
    }

    /// Decrements the count of an `Barrier` instance without blocking the current thread
    public func decrementAlone() {
        guard self.blockedThreadsCount.load(ordering: .acquiring) != 0 else {
            self.blockedThreadsCount.store(threadCount, ordering: .releasing)
            self.barrier.store(true, ordering: .releasing)
            return
        }
        guard
            self.blockedThreadsCount.wrappingDecrementThenLoad(ordering: .acquiringAndReleasing)
                != 0
        else {
            self.blockedThreadsCount.store(threadCount, ordering: .releasing)
            self.barrier.store(true, ordering: .releasing)
            return
        }
    }

    /// Decrements the count of the `Barrier` instance and
    /// blocks the current thread until the instance's count drops to zero
    public func decrementAndWait() {
        _ = self.barrier.compareExchange(
            expected: true, desired: false, ordering: .acquiringAndReleasing)
        guard
            self.blockedThreadsCount.wrappingDecrementThenLoad(ordering: .acquiringAndReleasing)
                != 0
        else {
            self.blockedThreadsCount.store(threadCount, ordering: .releasing)
            self.barrier.store(true, ordering: .releasing)
            return
        }
        while !self.barrier.load(ordering: .acquiring) {}
    }

    ///  Blocks the current thread until the instance's count drops to zero
    ///
    /// Warning - This function will deadlock if ``decrementAndWait`` method is called more or less than the count passed to the initializer
    public func waitForAll() {
        while !self.barrier.load(ordering: .acquiring) {}
    }
}
