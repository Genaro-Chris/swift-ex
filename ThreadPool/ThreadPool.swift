import Foundation

typealias Tasks = () -> Void

///
public final class ThreadPool: @unchecked Sendable {

    private let queue: Channel<Tasks>

    private let count: Int

    private let threadHandles: [Thread]

    private let barrier: Barrier

    private let wait: WaitType

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
        self.count = count
        self.wait = waitType
        self.queue = Channel()
        self.barrier = Barrier(value: count + 1)!
        self.threadHandles = start(queue: queue, count: count)
    }

    public static let globalPool = ThreadPool(count: ProcessInfo.processInfo.activeProcessorCount, waitType: .waitForAll)!

    ///
    /// - Parameter body:
    public func submit(_ body: @escaping () -> Void) {
        queue <- body
    }

    private func end() {
        threadHandles.forEach { $0.cancel() }
    }

    private func waitForAll() {
        (0 ..< count).forEach { _ in
            queue <-  { [barrier] in
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

private func start(
    queue: Channel<Tasks>, count: Int) -> [Thread] {
    let threadHandles = (0 ..< count).map { _ in
        Thread {
            for op in queue where !Thread.current.isCancelled {
                op()
            }
        }
    }
    threadHandles.forEach { $0.name = "Pool"; $0.start() }
    return threadHandles
}
