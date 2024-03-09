import Foundation

public class Mutex: @unchecked Sendable {

    var mutex: pthread_mutex_t
    private var mutexAttr: pthread_mutexattr_t

    ///
    public enum MutexType {
        case normal, recursive
    }

    ///
    /// - Parameter type:
    public init(type: MutexType = .normal) {
        mutex = pthread_mutex_t()
        mutexAttr = pthread_mutexattr_t()
        switch type {
            case .normal:
                pthread_mutexattr_settype(&mutexAttr, 0)
            case .recursive:
                pthread_mutexattr_settype(&mutexAttr, 1)
        }
        pthread_mutex_init(&mutex, &mutexAttr)
    }

    deinit {
        pthread_mutexattr_destroy(&mutexAttr)
        pthread_mutex_destroy(&mutex)
    }

    ///
    public func lock() {
        pthread_mutex_lock(&mutex)
    }

    ///
    /// - Returns:
    public func tryLock() -> Bool {
        pthread_mutex_trylock(&mutex) == 0 ? true : false
    }

    ///
    public func unlock() {
        pthread_mutex_unlock(&mutex)
    }

    ///
    /// - Parameter body:
    /// - Returns:
    @discardableResult
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
