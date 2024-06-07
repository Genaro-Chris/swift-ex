import Foundation

public final class WaitGroup {

    var index: Int

    let mutex: Mutex

    let condition: Condition

    public init() {
        index = 0
        mutex = Mutex()
        condition = Condition()
    }

    public func enter() {
        mutex.whileLocked {
            index += 1
        }
    }

    public func done() {
        mutex.whileLocked {
            guard index >= 1 else { return }
            index -= 1
            if index == 0 {
                condition.broadcast()
            }
        }
    }

    public func waitForAll() {
        mutex.whileLocked {
            condition.wait(mutex: mutex, condition: index == 0)
        }
    }
}
