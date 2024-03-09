import CXX_Thread

public final class MainExecutor: SerialExecutor, @unchecked Sendable {

    @_hasStorage private var jobQueue: JobQueue<UnownedJob> {
        JobQueue()
    }

    public init() {
        jobQueue = JobQueue()
    }

    private let threadHandle = SingleThread.create()

    public func enqueue(_ job: consuming ExecutorJob) {
        jobQueue <- UnownedJob(job)
        var executor = MainExecutor.sharedUnownedExecutor
        // warning: forming 'UnsafeRawPointer' to a variable of type 'JobQueue'; this is likely incorrect because 'JobQueue' may contain an object reference
        //threadHandle.submitTaskWithExecutor(&executor, &jobQueue, helper(_:_:))
        /* proposed solutuon crashes the application
        withUnsafePointer(to: jobQueue) {
            threadHandle.submitTaskWithExecutor(&executor, $0, helper(_:_:))
        } */
        // also withUnsafe[Mutable]Pointer(to:), withUnsafeBytes(of:)
        withUnsafeMutableBytes(of: &jobQueue) { rawPtr in
            threadHandle.submitTaskWithExecutor(
                &executor, rawPtr.baseAddress!, helper(_:_:))
        }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

extension MainExecutor {

    public static var shared: MainExecutor = .init()

    public static let sharedUnownedExecutor: UnownedSerialExecutor =
        UnownedSerialExecutor(ordinary: shared)

}
