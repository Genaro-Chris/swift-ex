private import Foundation

class JobQueue<Element>: @unchecked Sendable {
    private var array: [Element] = Array()
    private let lock = NSLock()
    func enqueue(_ val: Element) {
        lock.lock()
        defer {
            lock.unlock()
        }
        array.append(val)
    }

    func dequeue() -> Element? {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard array.first != nil else {
            return nil
        }
        return array.removeFirst()
    }
    static func <- (this: JobQueue, value: Element) {
        this.enqueue(value)
    }
    static prefix func <- (this: JobQueue) -> Element? {
        this.dequeue()
    }
}

internal func helper(_ exe: UnsafeRawPointer, _ store: UnsafeRawPointer) {
    let executor = exe.load(as: UnownedSerialExecutor.self)
    (<-store.load(as: JobQueue<UnownedJob>.self))?.runSynchronously(on: executor)

}

prefix operator <-
infix operator <-
