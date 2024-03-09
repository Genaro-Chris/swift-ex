import Foundation
import Primitives

public final class LockCustomExecutor: SerialExecutor {
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    let lock = Lock()

    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        ThreadPool.globalPool.submit { [lock] in
            lock.whileLocked {
                job.runSynchronously(on: executor)
            }
        }
    }

    static let shared = CustomGlobalExecutor()

}
