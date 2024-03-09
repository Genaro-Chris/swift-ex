prefix operator <-
infix operator <-

/// ThreadSafe queue for multithreaded execution context
public struct Queue<Element>: @unchecked Sendable {

    private let order: Order

    private let buffer: Locked<Buffer<Element>>

    /// Initializes an instance of the `Queue` type with a specific dequeuing `Order` type
    /// - Parameter order: order to be used when dequeuing
    public init(order: Order = .firstOut) {
        self.order = order
        self.buffer = Locked(Buffer())
    }

    /// Enqueue an item into the queue
    /// - Parameter item: item to be enqueued
    public func enqueue(_ item: Element) {
        self.buffer.updateWhileLocked { $0.enqueue(item) }
    }

    /// Dequeues an item from the queue using the specified `Order`
    /// - Returns: an item or nil if the queue is empty
    public func dequeue() -> Element? {
        return self.buffer.updateWhileLocked { $0.dequeue(order: self.order) }
    }

    /// Clears the remaining enqueued items
    public func clear() {
        self.buffer.updateWhileLocked { $0.clear() }
    }
}

extension Queue {

    /// Enqueues an item into a `Queue` instance
    public static func <- (this: Queue, value: Element) {
        this.enqueue(value)
    }

    /// Dequeues an item from a `Queue` instance
    public static prefix func <- (this: Queue) -> Element? {
        this.dequeue()
    }

    /// Number of items in the `Queue` instance
    public var length: Int {
        return buffer.count
    }

    /// Indicates if `Queue` instance is empty or not
    public var isEmpty: Bool {
        return buffer.isEmpty
    }
}
