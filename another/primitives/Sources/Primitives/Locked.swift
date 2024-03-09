import Atomics
import Foundation

///.
@propertyWrapper
@dynamicMemberLookup
public final class Locked<Value>: @unchecked Sendable {

    private let lock: Lock

    private var value: Value

    public var wrappedValue: Value {
        get {
            return self.updateWhileLocked { $0 }
        }
        set {
            self.updateWhileLocked { $0 = newValue }
        }
    }

    /// Initialises an instance of the `Locker` type with a instance
    public init(_ value: Value) {
        self.value = value
        self.lock = Lock()
    }

    ///
    /// - Parameter using:
    /// - Returns:
    public func updateWhileLocked<T>(_ using: (inout Value) throws -> T) rethrows -> T {
        return try self.lock.whileLocked {
            return try using(&self.value)
        }
    }

    public init(wrappedValue: Value) {
        self.value = wrappedValue
        self.lock = Lock()
    }

    public var projectedValue: Locked<Value> {
        return self
    }
}

extension Locked {

    public subscript<T>(dynamicMember memberKeyPath: KeyPath<Value, T>) -> T {
        get {
            self.updateWhileLocked { $0[keyPath: memberKeyPath] }
        }
    }

    public subscript<T>(dynamicMember memberKeyPath: WritableKeyPath<Value, T>) -> T {
        get {
            self.updateWhileLocked { $0[keyPath: memberKeyPath] }
        }
        set {
            self.updateWhileLocked { $0[keyPath: memberKeyPath] = newValue }
        }
    }

}

extension Locked where Value: AnyObject {

    public subscript<T>(dynamicMember memberKeyPath: ReferenceWritableKeyPath<Value, T>) -> T {
        get {
            self.updateWhileLocked { $0[keyPath: memberKeyPath] }
        }
        set {
            self.updateWhileLocked { $0[keyPath: memberKeyPath] = newValue }
        }
    }
}
