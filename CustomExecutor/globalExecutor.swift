import CXX_Thread
import ThreadPool

/// Example of a custom Executor of an actor
public final class CustomGlobalExecutor: SerialExecutor, @unchecked Sendable {

    @_hasStorage private var jobQueue: JobQueue<UnownedJob> {
        JobQueue()
    }

    public init() {
        jobQueue = JobQueue()
    }

    //private let threadpool = ThreadPool.create(CPU_Count)

    private let pool = ThreadPool(count: Int(CPU_Count))

    public func enqueue(_ job: consuming ExecutorJob) {
        jobQueue <- UnownedJob(job)
        // warning: forming 'UnsafeRawPointer' to a variable of type 'JobQueue'; this is likely incorrect because 'JobQueue' may contain an object reference
        // threadHandle.submitTaskWithExecutor(&executor, &jobQueue, helper(_:_:))
        // proposed solutuon crashes the application
        /* withUnsafePointer(to: &jobQueue) { rawPtr in
            threadpool.submit(rawPtr) {
                let jobQueue = $0.load(as: JobQueue<UnownedJob>.self)
                (<-jobQueue)?.runSynchronously(on: .generic)
            }
        } */
        pool?.submit { [weak self] in
            guard let self else {
                return
            }
            (<-jobQueue)?.runSynchronously(on: .generic)
        }

    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

extension CustomGlobalExecutor {

    public static let shared: CustomGlobalExecutor = .init()

    public static var sharedUnownedExecutor: UnownedSerialExecutor =
        UnownedSerialExecutor(ordinary: shared)

}

extension UnownedSerialExecutor {
    public static let sharedGlobalExecutor = CustomGlobalExecutor()

    public static let generic: Self =
        sharedGlobalExecutor.asUnownedSerialExecutor()
}


extension CustomGlobalExecutor: _TaskExecutor {
    @_implements(_TaskExecutor,enqueue)
    public func enqueueTask(_ job: consuming ExecutorJob) {
        jobQueue <- UnownedJob(job)
        
        pool?.submit { [weak self] in
            guard let self else {
                return
            }
            (<-jobQueue)?.runSynchronously(on: .generic)
        }
    }

    public func asUnownedTaskExecutor() -> UnownedTaskExecutor {
        UnownedTaskExecutor(ordinary: self)
    }

}
