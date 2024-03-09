import Atomics
import Foundation

infix operator <-

/// A blocking threadsafe queue for multithreaded execution context
public struct Channel<Element>: @unchecked Sendable {

    private let order: Order

    private let buffer: Locked<Buffer<Element>>

    private let cancel: ManagedAtomic<Bool>

    private let received: ManagedAtomic<Bool>

    private let sent: ManagedAtomic<Bool>

    /// Initializes an instance of the `Channel` type with a specific dequeuing `Order` type
    /// - Parameters:
    ///   - order: order to be used when dequeuing
    public init(order: Order = .firstOut) {
        self.order = order
        self.buffer = Locked(Buffer())
        self.cancel = ManagedAtomic(false)
        self.sent = ManagedAtomic(false)
        self.received = ManagedAtomic(true)
    }

    /// Enqueue an item into the queue
    /// - Parameter item: item to be enqueued
    public func enqueue(_ item: Element) {
        guard !self.cancel.load(ordering: .relaxed) else {
            return
        }
        defer {
            _ = self.sent.compareExchange(
                expected: false, desired: true, ordering: .acquiringAndReleasing)
        }
        while !self.received.weakCompareExchange(
            expected: true, desired: false, ordering: .acquiringAndReleasing
        ).exchanged {
            if self.cancel.load(ordering: .relaxed) {
                return
            }
            Thread.sleep(forTimeInterval: 0.0000000000000000001)
        }
        self.buffer.updateWhileLocked { $0.enqueue(item) }
    }

    /// Dequeues an item from the queue using the specified `Order`
    /// - Returns: an item or nil if the queue is empty
    public func dequeue() -> Element? {
        if self.cancel.load(ordering: .relaxed) && !self.isEmpty {
            return self.buffer.updateWhileLocked { $0.dequeue(order: self.order) }
        } else if self.cancel.load(ordering: .relaxed) {
            return nil
        }

        while !self.sent.weakCompareExchange(
            expected: true, desired: false, ordering: .acquiringAndReleasing
        ).exchanged {
            if self.cancel.load(ordering: .relaxed) {
                return nil
            }
            Thread.sleep(forTimeInterval: 0.0000000000000000001)
        }
        _ = self.received.compareExchange(
            expected: false, desired: true, ordering: .acquiringAndReleasing)
        return self.buffer.updateWhileLocked { $0.dequeue(order: self.order) }
    }

    /// Clears the remaining enqueued items
    public func clear() {
        self.buffer.updateWhileLocked { $0.clear() }
    }

    /// Cancels both the sending and receiving part of the queue
    public func cancelQueue() {
        self.cancel.store(true, ordering: .relaxed)
    }
}

extension Channel {

    /// Enqueues an item into a `Channel` instance
    public static func <- (this: Channel, value: Element) {
        this.enqueue(value)
    }

    /// Number of items in the `Channel` instance
    public var length: Int {
        return buffer.count
    }

    /// Indicates if `Channel` instance is empty or not
    public var isEmpty: Bool {
        return buffer.isEmpty
    }
}

extension Channel: IteratorProtocol, Sequence {
    public mutating func next() -> Element? {
        return self.dequeue()
    }

}
