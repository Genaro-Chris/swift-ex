import Foundation
import _Backtracing

public class TSPool: @unchecked Sendable {

    private let queue = STSQueue<() -> Void>()

    private let count: UInt

    private(set) var started = false

    fileprivate var threadHandles: [Thread] {
        var threadpool = [Thread]()
        threadpool.reserveCapacity(Int(count))
        for _ in 0..<count {
            threadpool.append(
                Thread { [weak self] in
                    guard let self else {
                        return
                    }
                    for op in queue {
                        switch op {
                        case let .ready(work): work()

                        default:
                            Thread.yield()
                            continue
                        }
                    }

                    while case let .some(op) = queue.next(),
                        case let STSQueue<() -> Void>.QueueOp.ready(work) = op
                    {
                        work()
                    }
                }
            )
        }
        return threadpool
    }

    public init(count: UInt) {
        self.count = count

    }

    public func submit(_ body: @escaping () -> Void) {
        queue <- {
            print("\(#function) \(Thread.current.debugDescription)")
            body()
        }
        if !started {
            threadHandles.forEach({ $0.start() })
            started = true
        }
    }

    deinit {
        for _ in 0..<count {
            queue.cancel()
        }
        threadHandles.forEach { handle in
            handle.cancel()
        }
    }
}

func captureBackTrace() throws {
    let capture = try _Backtracing.Backtrace.capture(
        algorithm: .auto, limit: 30, offset: 0, top: 100)
    print(capture)
}

public final class SingleTSPool: @unchecked Sendable {

    private(set) var started = false

    public init() {}

    let queue = STSQueue<() -> Void>()

    var threadHandle: Thread {
        Thread { [weak self] in
            guard let self else {
                return
            }
            for op in queue {
                switch op {
                case let .ready(work): work()

                default: continue

                }
            }
        }
    }

    public func submit(_ body: @escaping () -> Void) {
        queue <- body
        if !started {
            threadHandle.start()
            started = true
        }
    }

    deinit {
        queue.cancel()
        threadHandle.cancel()
    }
}
