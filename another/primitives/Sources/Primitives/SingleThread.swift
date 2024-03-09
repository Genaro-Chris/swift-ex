import Foundation

public final class SingleThread: Sendable {

    private let handle: UniqueThread

    /// Indicates if thread is currently executing some tasks
    /// not just idle looping and waiting for jobs to be enqueued
    public var isBusy: Bool {
        handle.isBusyExecuting
    }

    /// Block the caller's thread until thread is free of all enqueued tasks
    public func pollAll() {
        queue <- .wait
        barrier.decrementAndWait()
    }

    private let queue: Queue<QueueOperation>

    private let waitType: WaitType

    private let barrier: Barrier!

    /// Initialises an instance of `SingleThread` type
    /// - Parameter waitType: value of `WaitType`
    public init(waitType: WaitType = .waitForAll) {
        self.waitType = waitType
        queue = Queue<QueueOperation>()
        barrier = Barrier(count: 2)
        handle = start(queue: queue, barrier: barrier)
    }

    private func end() {
        handle.cancel()
    }

    /// Submits a closure for execution
    /// - Parameter body: a non-throwing closure that takes and returns void
    public func submit(_ body: @escaping () -> Void) {
        queue <- .ready(element: body)
    }

    deinit {
        switch waitType {
            case .cancelAll: end()

            case .waitForAll:
                pollAll()
                end()
        }
        handle.join()
    }
}

private func start(queue: Queue<QueueOperation>, barrier: Barrier) -> UniqueThread {
    UniqueThread(name: "SingleThread") { [queue, barrier] isBusy in
        loop: while true {
            switch (queue.dequeue(), Thread.current.isCancelled) {
                case (nil, false): continue
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
                        default:
                            break loop
                    }
                default: break loop
            }
        }
    }
}

extension SingleThread: CustomStringConvertible {
    public var description: String {
        "Single Thread of \(waitType) type"
    }
}

extension SingleThread: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Single Thread of \(waitType) type of name: \(handle.name!)"
    }
}
