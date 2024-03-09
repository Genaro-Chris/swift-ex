import Foundation

///
public final class ThreadPool: Sendable {

    private let queue: Queue<QueueOperation>

    private let count: Int

    private let threadHandles: [UniqueThread]

    private let barrier: Barrier!

    private let wait: WaitType

    /// This represents a global threadpool similar to `Dispatch.global()`
    /// as it contains the same number of threads as the total number of processor count
    public static let globalPool: ThreadPool = ThreadPool(
        count: ProcessInfo.processInfo.processorCount, waitType: .waitForAll)!

    /// Indicates if all threads in the threadpool are currently executing some tasks
    /// not just idle looping and waiting for jobs to be enqueued
    public var isBusyExecuting: Bool {
        threadHandles.allSatisfy {
            $0.isBusyExecuting
        }
    }

    /// Block the caller's thread until all threads  in the pool are freed of all enqueued tasks
    public func pollAll() {
        (0 ..< count).forEach { _ in
            queue <- .wait
        }
        barrier.decrementAndWait()
    }

    /// Initializes an instance of the `ThreadPool` type
    /// - Parameters:
    ///   - count: Number of threads to used in the pool
    ///   - waitType: value of `WaitType`
    /// Note: Returns nil if the count argument is less than one
    public init?(
        count: Int, waitType: WaitType = .cancelAll
    ) {
        guard count >= 1 else {
            return nil
        }
        self.count = count
        self.wait = waitType
        self.queue = Queue(order: .firstOut)
        self.barrier = Barrier(count: UInt(count + 1))
        self.threadHandles = start(queue: queue, count: count, barrier: barrier)
    }

    /// Submits a closure for execution in one of the pool's threads
    /// - Parameter body: a non-throwing closure that takes and returns void
    public func submit(_ body: @escaping () -> Void) {
        queue <- .ready(element: body)
    }

    private func end() {
        threadHandles.forEach { $0.cancel() }
    }

    deinit {
        switch wait {
            case .cancelAll:
                end()
            case .waitForAll:
                pollAll()
                end()
        }
        threadHandles.forEach { $0.join() }
    }
}

private func start(
    queue: Queue<QueueOperation>, count: Int, barrier: Barrier
) -> [UniqueThread] {
    (0 ..< count).map { index in
        UniqueThread(name: "ThreadPool #\(index)") { isBusy in
            loop: while true {
                switch (queue.dequeue(), Thread.current.isCancelled) {
                    case (nil, false): continue loop
                    case let (.some(op), cancelled):
                        switch (op, cancelled) {
                            case let (.ready(work), false):
                                isBusy.store(true, ordering: .relaxed)
                                defer {
                                    isBusy.store(false, ordering: .relaxed)
                                }
                                work()
                            case (.wait, _):
                                barrier.decrementAndWait()
                            default: break loop
                        }
                    default: break loop
                }
            }

        }
    }
}

extension ThreadPool: CustomStringConvertible {
    public var description: String {
        "ThreadPool of \(wait) type with \(count) thread\(count == 1 ? "" : "s")"
    }
}

extension ThreadPool: CustomDebugStringConvertible {
    public var debugDescription: String {
        let threadNames = threadHandles.map { handle in
            " - " + (handle.name ?? "Threadpool") + "\n"
        }.reduce("") { acc, name in
            return acc + name
        }
        return "ThreadPool of \(wait) type with \(count) thread\(count == 1 ? "" : "s")"
            + ":\n" + threadNames

    }
}
