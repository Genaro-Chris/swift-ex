/* import Foundation
@preconcurrency import Primitives

public final class CustomGlobalExecutor: SerialExecutor {
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    let pool: ThreadPool

    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        pool.submit {
            job.runSynchronously(on: executor)
        }
    }

    public func enqueue(_ job: __owned UnownedJob, with deadline: Double) {
        let executor = asUnownedSerialExecutor()
        pool.submit {
            Thread.sleep(forTimeInterval: deadline)
            job.runSynchronously(on: executor)
        }
    }

    init(_ pool: ThreadPool) {
        self.pool = pool
    }

    static let shared = CustomGlobalExecutor(SimpleThreadPool.globalPool)

}

func replaceGlobalConcurrencyHook() {
    typealias OpaqueJob = UnownedJob
    typealias EnqueueOriginal = @convention(thin) (OpaqueJob) -> Void
    typealias EnqueueHook = @convention(thin) (OpaqueJob, EnqueueOriginal) -> Void

    let handle = dlopen(nil, RTLD_LAZY)
    let enqueueGlobalHookPtr = dlsym(handle, "swift_task_enqueueGlobal_hook")!
        .assumingMemoryBound(to: EnqueueHook.self)

    enqueueGlobalHookPtr.pointee = { opaqueJob, _ in
        CustomGlobalExecutor.shared.enqueue(opaqueJob)
    }
}

func replaceGlobalConcurrencyDelayHook() {
    typealias OpaqueJob = UnownedJob
    typealias EnqueueOriginal = @convention(thin) (OpaqueJob) -> Void
    typealias EnqueueHook = @convention(thin) (Int64, OpaqueJob, EnqueueOriginal) -> Void

    let handle = dlopen(nil, RTLD_LAZY)
    let enqueueGlobalDelayHookPtr = dlsym(handle, "swift_task_enqueueGlobalWithDelay_hook")!
        .assumingMemoryBound(to: EnqueueHook.self)

    enqueueGlobalDelayHookPtr.pointee = { nsecs, opaqueJob, _ in
        let delay = Double(nsecs) / Double(1_000_000_000)
        CustomGlobalExecutor.shared.enqueue(opaqueJob, with: delay)
    }
}

func replaceGlobalConcurrencyDeadlineHook() {
    typealias OpaqueJob = UnownedJob
    typealias EnqueueOriginal = @convention(thin) (OpaqueJob) -> Void
    typealias EnqueueHook = @convention(thin) (
        Int64, Int64, Int64, Int64, Int32, OpaqueJob, EnqueueOriginal
    ) -> Void

    let handle = dlopen(nil, RTLD_LAZY)
    let enqueueGlobalDeadlineHookPtr = dlsym(handle, "swift_task_enqueueGlobalWithDeadline_hook")!
        .assumingMemoryBound(to: EnqueueHook.self)

    enqueueGlobalDeadlineHookPtr.pointee = { sec, nsec, tsec, tnsec, clock, opaqueJob, _ in
        let deadline = getDeadline(sec, nsec, tsec, tnsec, clock)
        print("Deadline hook called \(deadline)")
        CustomGlobalExecutor.shared.enqueue(opaqueJob, with: deadline)
    }
}

func getDeadline(_ sec: Int64, _ nsec: Int64, _ tsec: Int64, _ tnsec: Int64, _ clock: Int32)
    -> Double {
    let nsecsPerSecs: Int64 = 1_000_000_000

    let timeSpec = get_current_time(clock: ClockID(rawValue: clock) ?? .continous)
    let timeoutSecs = Double((((sec + tsec) * nsecsPerSecs) + (tnsec + nsec)) / nsecsPerSecs)
    let currentSecs =
        Double(
            ((Int64(timeSpec.tv_sec) * nsecsPerSecs)
                + (Int64(timeSpec.tv_nsec))) / nsecsPerSecs)

    return timeoutSecs - currentSecs
}

func get_current_time(clock: ClockID) -> timespec {
    var timespec = timespec(tv_sec: __time_t(0), tv_nsec: 0)
    timespec_get(&timespec, 0)
    switch clock {
    case .continous:
        #if os(Linux)
            clock_gettime(CLOCK_BOOTTIME, &timespec)
        #elseif os(macOS)
            clock_gettime(CLOCK_MONOTONIC_RAW, &timespec)
        #endif
    case .suspending:
        #if os(Linux)
            clock_gettime(CLOCK_MONOTONIC, &timespec)
        #elseif os(macOS)
            clock_gettime(CLOCK_UPTIME_RAW, &timespec)
        #endif
    }
    return timespec
}

enum ClockID: Int32 {

    case continous = 1, suspending
}
 */