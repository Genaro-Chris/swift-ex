import Atomics

internal enum Stages: AtomicValue, AtomicStorage, Comparable {
    static func atomicWeakCompareExchange(
        expected: Stages,
        desired: __owned Stages,
        at pointer: UnsafeMutablePointer<Stages>,
        successOrdering: Atomics.AtomicUpdateOrdering,
        failureOrdering: Atomics.AtomicLoadOrdering
    ) -> (exchanged: Bool, original: Stages) {
        let oldValue = pointer.pointee
        if oldValue != expected {
            return (false, oldValue)
        }
        #if swift(>=5.9)
            pointer.pointee = consume desired
        #else
            pointer.pointee = desired
        #endif
        return (true, oldValue)
    }

    static func atomicCompareExchange(
        expected: Stages,
        desired: __owned Stages,
        at pointer: UnsafeMutablePointer<Stages>,
        successOrdering: Atomics.AtomicUpdateOrdering,
        failureOrdering: Atomics.AtomicLoadOrdering
    ) -> (exchanged: Bool, original: Stages) {
        let oldValue = pointer.pointee
        if oldValue != expected {
            return (false, oldValue)
        }
        #if swift(>=5.9)
            pointer.pointee = consume desired
        #else
            pointer.pointee = desired
        #endif
        return (true, oldValue)
    }

    init(_ value: __owned Stages) {
        self = value
    }

    func dispose() -> Stages {
        #if swift(>=5.9)
            return consume self
        #else
            return self
        #endif
    }

    static func atomicLoad(
        at pointer: UnsafeMutablePointer<Stages>,
        ordering: Atomics.AtomicLoadOrdering
    ) -> Stages {
        pointer.pointee
    }

    static func atomicStore(
        _ desired: __owned Stages,
        at pointer: UnsafeMutablePointer<Stages>,
        ordering: Atomics.AtomicStoreOrdering
    ) {
        #if swift(>=5.9)
            pointer.pointee = consume desired
        #else
            pointer.pointee = desired
        #endif
    }

    static func atomicExchange(
        _ desired: __owned Stages,
        at pointer: UnsafeMutablePointer<Stages>,
        ordering: Atomics.AtomicUpdateOrdering
    ) -> Stages {
        let oldValue = pointer.pointee
        #if swift(>=5.9)
            pointer.pointee = consume desired
        #else
            pointer.pointee = desired
        #endif
        return oldValue
    }

    typealias Value = Self
    typealias AtomicRepresentation = Self

    case ready, pending, notyet
}
