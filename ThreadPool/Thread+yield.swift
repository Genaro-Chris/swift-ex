import class Foundation.Thread

#if canImport(Darwin)
    import Darwin
    private func sys_sched_yield() {
        pthread_yield_np()
    }
#elseif os(Windows)
    import ucrt
    import WinSDK
    private func sys_sched_yield() {
        Sleep(0)
    }
#else
    #if canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #else
        #error("The concurrency atomics module was unable to identify your C library.")
    #endif

    private func sys_sched_yield() {
        _ = sched_yield()
    }
#endif

extension Thread {

    static func yield() {
        sys_sched_yield()
    }
}
