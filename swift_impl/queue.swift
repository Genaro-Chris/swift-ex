import Foundation

extension NSRecursiveLock {

    func Do<T>(body: () -> T) -> T {
        self.lock()
        defer {
            self.unlock()
        }
        let val = body()

        return val
    }
}

extension NSLock {

    func Do<T>(body: () -> T) -> T {
        self.lock()
        defer {
            self.unlock()
        }
        let val = body()

        return val
    }
}

// My impl
public class TSQueue<Element>: @unchecked Sendable {

    public enum QueueOp {
        case ready(element: Element)
        case notYet
        case stop
    }

    private var array: [QueueOp] = Array()
    private let lock = NSRecursiveLock()
    func enqueue(_ val: Element) {
        enqueue(.ready(element: val))
    }

    private func enqueue(_ op: QueueOp) {
        lock.Do {
            array.append(op)
        }
    }

    public func cancel() {
        enqueue(.stop)
    }

    func dequeue() -> QueueOp {
        return lock.Do {
            if array.isEmpty {
                return .notYet
            }
            return array.removeFirst()
        }
    }
    public init() {}
}

extension TSQueue {
    public static func <- (this: TSQueue, value: Element) {
        this.enqueue(value)
    }
    public static prefix func <- (this: TSQueue) -> QueueOp {
        this.dequeue()
    }

}

extension TSQueue: Sequence, IteratorProtocol {
    public func next() -> QueueOp? {
        let value = <-self
        if case .stop = value {
            return nil
        }
        return value
    }
}

prefix operator <-
infix operator <-
