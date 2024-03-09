import Atomics
import Foundation

infix operator <-

/// A blocking threadsafe queue for multithreaded execution context
public struct BufferedChannel<Element>: @unchecked Sendable {

    private let order: Order

    private let buffer: Locked<Buffer<Element>>

    private let cancel: ManagedAtomic<Bool>

    private let capacity: Int

    private let sent: ManagedAtomic<Int>

    /// Initializes an instance of the `BufferedChannel` type with a specific dequeuing `Order` type
    /// - Parameters:
    ///   - count: `Channel` maximum capacity
    ///   - order: order to be used when dequeuing
    public init(count: Int, order: Order = .firstOut) {
        self.capacity = count
        self.order = order
        self.buffer = Locked(Buffer())
        self.cancel = ManagedAtomic(false)
        self.sent = ManagedAtomic(0)
    }

    /// Enqueue an item into the queue
    /// - Parameter item: item to be enqueued
    public func enqueue(_ item: Element) {
        guard !self.cancel.load(ordering: .relaxed) else {
            return
        }

        self.sent.wrappingIncrement(ordering: .acquiringAndReleasing)

        while self.sent.load(ordering: .acquiring) > self.capacity {
            if self.cancel.load(ordering: .relaxed) {
            }
            Thread.sleep(forTimeInterval: 0.0000000000000000001)
        }

        self.buffer.updateWhileLocked { $0.enqueue(item) }
    }

    /// Dequeues an item from the queue using the specified `Order`
    /// - Returns: an item or nil if the queue is empty
    public func dequeue() -> Element? {
        if self.cancel.load(ordering: .relaxed) && !self.isEmpty {
            self.sent.wrappingDecrement(ordering: .acquiringAndReleasing)
            return self.buffer.updateWhileLocked { $0.dequeue(order: self.order) }
        } else if self.cancel.load(ordering: .relaxed) {
            return nil
        }

        while self.sent.load(ordering: .acquiring) == 0 {
            if self.cancel.load(ordering: .relaxed) {
                return nil
            }
            Thread.sleep(forTimeInterval: 0.0000000000000000001)
        }
        defer {
            self.sent.wrappingDecrement(ordering: .acquiringAndReleasing)
        }

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

extension BufferedChannel {

    /// Enqueues an item into a `BufferedChannel` instance
    public static func <- (this: BufferedChannel, value: Element) {
        this.enqueue(value)
    }

    /// Number of items in the `BufferedChannel` instance
    public var length: Int {
        return buffer.count
    }

    /// Indicates if `BufferedChannel` instance is empty or not
    public var isEmpty: Bool {
        return buffer.isEmpty
    }
}

extension BufferedChannel: IteratorProtocol, Sequence {
    public mutating func next() -> Element? {
        return self.dequeue()
    }

}
