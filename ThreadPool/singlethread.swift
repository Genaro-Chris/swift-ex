import Foundation

public final class SingleThread: @unchecked Sendable {

    private let handle: Thread

    ///
    public func poll() {
        waitForAll()
    }

    private let queue: ThreadSafeQueue<Tasks>

    private let waitType: WaitType

    private let barrier: Barrier

    ///
    /// - Parameter waitType:
    public init(waitType: WaitType = .waitForAll) {
        self.waitType = waitType
        queue = ThreadSafeQueue()
        barrier = Barrier(value: 2)!
        handle = start(queue: queue)
    }

    private func end() {
        handle.cancel()
    }

    private func waitForAll() {
        queue <- { [barrier] in barrier.arriveAndWait() } 
        barrier.arriveAndWait()
    }

    public func submit(_ body: @escaping () -> Void) {
        queue <- body
    }

    deinit {
        switch waitType {
            case .cancelAll: end()

            case .waitForAll:
                waitForAll()
                end()
        }
    }
}

private func start(queue: ThreadSafeQueue<Tasks>) -> Thread {
    let thread = Thread { [queue] in
        while let op = queue.next() {
            op()
        }
    }
    thread.start()
    return thread
}
