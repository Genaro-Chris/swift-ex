import Foundation

///
public final class WorkerPool {

    private let threadHandles: [Thread]

    private let barrier: Barrier

    private let wait: WaitType

    private let queue: Channel<Tasks>

    ///
    public func poll() {
        waitForAll()
    }

    ///
    /// - Parameters:
    ///   - count:
    ///   - waitType:
    public init?(count: Int, waitType: WaitType = .cancelAll) {
        if count < 1 {
            return nil
        }
        self.wait = waitType
        self.barrier = Barrier(value: count + 1)!
        queue = Channel()
        threadHandles = start(queue: queue, size: count)
    }

    ///
    /// - Parameter body:
    public func submit(_ body: @escaping () -> Void) {
        queue <- body
    }

    private func end() {
        queue.clear()
        queue.close()
        threadHandles.forEach {
            $0.cancel()
        }
    }

    private func waitForAll() {
        threadHandles.forEach { _ in
            queue <- { [barrier] in
                barrier.arriveAndWait()
            }
        }
        barrier.arriveAndWait()
    }

    deinit {
        switch wait {
        case .cancelAll:
            end()
        case .waitForAll:
            waitForAll()
            end()
        }
    }
}

private func start(queue: Channel<Tasks>, size: Int) -> [Thread] {
    let threadHandles = (0..<size).map { _ in
        Thread { [queue] in
            var iterator = queue.makeIterator()
            while !Thread.current.isCancelled {
                if let work = iterator.next() {
                    work()
                }
            }
        }
    }
    threadHandles.forEach {
        $0.name = "Pool"
        $0.start()
    }
    return threadHandles
}
