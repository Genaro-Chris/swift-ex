/* import CXX_Thread

/// Example of a custom Executor of an actor
public final class CustomExecutor: SerialExecutor, @unchecked Sendable {

    @_hasStorage private var jobQueue: JobQueue<UnownedJob> {
        JobQueue()
    }

    enum ExecutorKind {
        case distributedKind, normalKind
    }

    init(kind: ExecutorKind) {
        self.kind = kind
        jobQueue = JobQueue()
    }

    let kind: ExecutorKind

    let threadHandle = SingleThread.create()

    public func enqueue(_ job: consuming ExecutorJob) {
        jobQueue <- UnownedJob(job)
        switch kind {
            case .distributedKind:
                var executor = CustomExecutor.sharedDistributedUnownedExecutor

                // warning: forming 'UnsafeRawPointer' to a variable of type 'JobQueue'; this is likely incorrect because 'JobQueue' may contain an object reference
                // threadHandle.submitTaskWithExecutor(&executor, &jobQueue, helper(_:_:))
                // proposed solutuon
                withUnsafeMutableBytes(of: &jobQueue) { rawPtr in
                    threadHandle.submitTaskWithExecutor(
                        &executor, rawPtr.baseAddress!, helper(_:_:))
                }
            case .normalKind:
                var executor = CustomExecutor.sharedUnownedExecutor
                // warning: forming 'UnsafeRawPointer' to a variable of type 'JobQueue'; this is likely incorrect because 'JobQueue' may contain an object reference
                //threadHandle.submitTaskWithExecutor(&executor, &jobQueue, helper(_:_:))
                //proposed solution
                withUnsafeMutableBytes(of: &jobQueue) { rawPtr in
                    threadHandle.submitTaskWithExecutor(
                        &executor, rawPtr.baseAddress!, helper(_:_:))
                }
        }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

extension CustomExecutor {

    fileprivate static var sharedDistributed: CustomExecutor =
        .init(
            kind: .distributedKind)

    fileprivate static var shared: CustomExecutor = .init(kind: .normalKind)

    public static let sharedUnownedExecutor: UnownedSerialExecutor =
        shared.asUnownedSerialExecutor()

    public static let sharedDistributedUnownedExecutor: UnownedSerialExecutor =
        sharedDistributed.asUnownedSerialExecutor()

}

extension UnownedSerialExecutor {

    static let sharedSample: SampleFIFOCustomExecutor = .init()

    public static var sharedSampleExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: sharedSample)
    }
}

extension UnownedSerialExecutor {

    fileprivate static var sharedDistributed: CustomExecutor =
        .init(
            kind: .distributedKind)

    fileprivate static var shared: CustomExecutor = .init(kind: .normalKind)

    public static var sharedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: shared)
    }

    public static var sharedDistributedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: sharedDistributed)
    }

}

public final class SampleFIFOCustomExecutor: SerialExecutor {
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

} */

import CXX_Thread

/// Example of a custom Executor of an actor
public final class CustomExecutor: SerialExecutor, @unchecked Sendable {

    @_hasStorage private var jobQueue: JobQueue<UnownedJob> {
        JobQueue()
    }

    enum ExecutorKind {
        case distributedKind, normalKind
    }

    init(kind: ExecutorKind) {
        self.kind = kind
        jobQueue = JobQueue()
    }

    let kind: ExecutorKind

    let threadHandle = SingleThread.create()

    public func enqueue(_ job: consuming ExecutorJob) {
        jobQueue <- UnownedJob(job)
        switch kind {
            case .distributedKind:
                var executor = UnownedSerialExecutor.sharedDistributedUnownedExecutor
                // warning: forming 'UnsafeRawPointer' to a variable of type 'JobQueue'; this is likely incorrect because 'JobQueue' may contain an object reference
                //threadHandle.submitTaskWithExecutor(&executor, &jobQueue, helper(_:_:))
                // solutuon
                // also withUnsafe[Mutable]Pointer(to:), withUnsafeBytes(of:)
                withUnsafeMutableBytes(of: &jobQueue) { rawPtr in
                    threadHandle.submitTaskWithExecutor(
                        &executor, rawPtr.baseAddress!, helper(_:_:))
                }

            case .normalKind:
                // warning: forming 'UnsafeRawPointer' to a variable of type 'JobQueue'; this is likely incorrect because 'JobQueue' may contain an object reference
                //threadHandle.submitTaskWithExecutor(&executor, &jobQueue, helper(_:_:))
                // solutuon
                // also withUnsafe[Mutable]Pointer(to:), withUnsafeBytes(of:)
                withUnsafeMutableBytes(of: &jobQueue) { rawPtr in
                    threadHandle.submit(
                        rawPtr.baseAddress!
                    ) { jobPtr in
                        let jobQueue = jobPtr.load(as: JobQueue<UnownedJob>.self)
                        (<-jobQueue)?.runSynchronously(on: .sharedUnownedExecutor)
                    }
                }
        /* crashes the application
                    withUnsafePointer(to: jobQueue) {
                        let rawPtr = UnsafeRawPointer($0)
                        threadHandle.submitTaskWithExecutor(&executor, rawPtr, helper(_:_:))
                    } */
        }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

extension UnownedSerialExecutor {

    fileprivate static var sharedDistributed: CustomExecutor =
        .init(
            kind: .distributedKind)

    fileprivate static var shared: CustomExecutor = .init(kind: .normalKind)

    public static var sharedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: shared)
    }

    public static var sharedDistributedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: sharedDistributed)
    }

    static let sharedSample: SampleFIFOCustomExecutor = .init()

    public static var sharedSampleExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: sharedSample)
    }
}

public final class SampleFIFOCustomExecutor: SerialExecutor {
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
