#if canImport(Darwin)
    import Darwin
#elseif os(Windows)
    import ucrt
    import WinSDK
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#else
    #error("Unable to identify your C library.")
#endif

///
public final class Condition {

    #if os(Windows)
        private let condition: UnsafeMutablePointer<CONDITION_VARIABLE>
    #else
        private let condition: UnsafeMutablePointer<pthread_cond_t>
        private let conditionAttr: UnsafeMutablePointer<pthread_condattr_t>
    #endif

    public init() {
        condition = UnsafeMutablePointer.allocate(capacity: 1)
        #if os(Windows)
            InitializeConditionVariable(condition)
        #else
            condition.initialize(to: pthread_cond_t())
            conditionAttr = UnsafeMutablePointer.allocate(capacity: 1)
            conditionAttr.initialize(to: pthread_condattr_t())
            pthread_condattr_init(conditionAttr)
            pthread_cond_init(condition, conditionAttr)
        #endif

    }

    deinit {
        #if os(Windows)
            // condition variables do not need to be explicitly destroyed
        #else
            pthread_condattr_destroy(conditionAttr)
            pthread_cond_destroy(condition)
            conditionAttr.deallocate()
        #endif
        condition.deallocate()
    }

    /// Blocks the current thread until a specified time interval is reached
    /// - Parameters:
    ///   - mutex:
    ///   - forTimeInterval:
    public func wait(mutex: Mutex, forTimeInterval timeoutSeconds: Double) {
        guard timeoutSeconds >= 0 else {
            return
        }

        #if os(Windows)
            var dwMilliseconds: DWORD = DWORD(timeoutSeconds * 1000)
            while true {
                let dwWaitStart = timeGetTime()
                if !SleepConditionVariableSRW(condition, mutex.mutex, dwMilliseconds, 0) {
                    let dwError = GetLastError()
                    if dwError == ERROR_TIMEOUT {
                        return
                    }
                    fatalError("SleepConditionVariableSRW: \(dwError)")
                }

                // NOTE: this may be a spurious wakeup, adjust the timeout accordingly
                dwMilliseconds -= (timeGetTime() - dwWaitStart)
            }

        #else
            // convert argument passed into nanoseconds
            let nsecPerSec: Int64 = 1_000_000_000
            let timeoutNS = Int64(timeoutSeconds * Double(nsecPerSec))

            // get the current clock id
            var clockID = clockid_t(0)
            pthread_condattr_getclock(conditionAttr, &clockID)

            // get the current time
            var curTime = timespec(tv_sec: 0, tv_nsec: 0)
            clock_gettime(clockID, &curTime)

            // calculate the timespec from the argument passed
            let allNSecs: Int64 = timeoutNS + Int64(curTime.tv_nsec) / nsecPerSec
            var timeoutAbs = timespec(
                tv_sec: curTime.tv_sec + Int(allNSecs / nsecPerSec),
                tv_nsec: curTime.tv_nsec + Int(allNSecs % nsecPerSec)
            )

            // wait until the time passed as argument as elapsed
            switch pthread_cond_timedwait(condition, mutex.mutex, &timeoutAbs) {
            case 0, ETIMEDOUT: ()
            case let err: fatalError("caught error \(err) when calling pthread_cond_timedwait")
            }
        #endif
    }

    /// Blocks the current thread until the condition return true
    /// - Parameters:
    ///   - mutex:
    ///   - condition:
    public func wait(mutex: Mutex, condition body: @autoclosure () -> Bool) {
        precondition(!mutex.tryLock(), "\(#function) must be called only while the mutex is locked")
        while !body() {
            #if os(Windows)
                let result = SleepConditionVariableSRW(condition, mutex.mutex, INFINITE, 0)
                precondition(
                    result,
                    "\(#function) failed in SleepConditionVariableSRW with error \(GetLastError())"
                )
            #else
                pthread_cond_wait(condition, mutex.mutex)
            #endif
        }

    }

    /// Blocks the current thread
    /// - Parameter mutex:
    public func wait(mutex: Mutex) {
        precondition(!mutex.tryLock(), "\(#function) must be called only while the mutex is locked")
        #if os(Windows)
            let result = SleepConditionVariableSRW(condition, mutex.mutex, INFINITE, 0)
            precondition(
                result,
                "\(#function) failed in SleepConditionVariableSRW with error \(GetLastError())"
            )
        #else
            pthread_cond_wait(condition, mutex.mutex)
        #endif
    }

    ///
    public func signal() {
        #if os(Windows)
            WakeConditionVariable(condition)
        #else
            pthread_cond_signal(condition)
        #endif
    }

    ///
    public func broadcast() {
        #if os(Windows)
            WakeAllConditionVariable(condition)
        #else
            pthread_cond_broadcast(condition)
        #endif
    }

}
