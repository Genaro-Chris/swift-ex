import Foundation
import Primitives

public final class CustomGlobalExecutor: SerialExecutor {
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        ThreadPool.globalPool.submit {
            job.runSynchronously(on: executor)
        }
    }

    static let shared = CustomGlobalExecutor()

}

func replaceGlobalConcurrencyHook() {
    typealias OpaqueJob = UnsafeMutableRawPointer
    typealias EnqueueOriginal = @convention(c) (OpaqueJob) -> Void
    typealias EnqueueHook = @convention(c) (OpaqueJob, EnqueueOriginal) -> Void

    Once.runOnce {
        let handle = dlopen(nil, RTLD_NOW)
        let enqueueGlobal_hook_ptr = dlsym(handle, "swift_task_enqueueGlobal_hook")!
            .assumingMemoryBound(to: EnqueueHook.self)

        enqueueGlobal_hook_ptr.pointee = { opaque_job, original in
            let job = unsafeBitCast(opaque_job, to: UnownedJob.self)
            CustomGlobalExecutor.shared.enqueue(job)
        }
    }
}
