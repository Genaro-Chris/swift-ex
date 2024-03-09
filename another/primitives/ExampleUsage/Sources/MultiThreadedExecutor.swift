import Foundation
import Primitives

final class MultiThreadedSerialJobExecutor: SerialExecutor {

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    init() {}

    private let mutex = Lock()

    private let threadHandle = ThreadPool(count: 2)

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        threadHandle?.submit { [weak self] in
            guard let self else {
                return
            }
            mutex.whileLocked {
                job.runSynchronously(on: executor)
            }
        }
    }

}
