#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#else
    #error("Unable to identify your C library.")
#endif

///
public class RWLock: @unchecked Sendable {

    var rwLock: pthread_rwlock_t
    var rwLockAttr: pthread_rwlockattr_t

    ///
    public enum RWLockPreference {

        ///
        case readingFirst
        ///
        case writingFirst
    }

    ///
    public init(preference: RWLockPreference = .readingFirst) {
        rwLockAttr = pthread_rwlockattr_t()
        rwLock = pthread_rwlock_t()
        switch preference {

            case .readingFirst: pthread_rwlockattr_setkind_np(&rwLockAttr, 0)

            case .writingFirst: pthread_rwlockattr_setkind_np(&rwLockAttr, 1)
        }
        pthread_rwlock_init(&rwLock, &rwLockAttr)

    }

    deinit {
        pthread_rwlockattr_destroy(&rwLockAttr)
        pthread_rwlock_destroy(&rwLock)
    }

    ///
    public func readLock() {
        pthread_rwlock_rdlock(&rwLock)
    }

    ///
    public func writeLock() {
        pthread_rwlock_wrlock(&rwLock)
    }

    ///
    @discardableResult
    public func tryReadLock() -> Bool {
        pthread_rwlock_tryrdlock(&rwLock) == 0 ? true : false
    }

    ///
    @discardableResult
    public func tryWriteLock() -> Bool {
        pthread_rwlock_wrlock(&rwLock) == 0 ? true : false
    }

    ///
    public func unlock() {
        pthread_rwlock_unlock(&rwLock)
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    public func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        readLock()
        defer { unlock() }
        return try body()
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    public func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        writeLock()
        defer { unlock() }
        return try body()
    }
}
