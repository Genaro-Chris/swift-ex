import CXX_Thread
import Foundation

public final class LockCustomExecutor: SerialExecutor {
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    private let threadHandle = SingleThread.create()

    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let byteCount =
            MemoryLayout<UnownedJob>.alignment * MemoryLayout<UnownedJob>.stride
        let pointer = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount, alignment: MemoryLayout<UnownedJob>.alignment)
        pointer.storeBytes(of: job, as: UnownedJob.self)
        threadHandle.submit(pointer) { jobptr in
            defer {
                jobptr.deallocate()
            }
            let job = jobptr.load(as: UnownedJob.self)
            job.runSynchronously(on: .sharedSampleExecutor)
        }
    }

}
