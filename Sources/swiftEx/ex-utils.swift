import Foundation
import Interface

/* public enum AsyncIterationMode: Sendable {
    /// Serial iteration performs each step in sequence, waiting for the previous one to complete before performing the next.
    case serial
    /// Concurrent iteration performs all steps in parallell, and resumes execution when all opeations are done.
    /// When applied to `asyncMap`, the results are returned in the original order.
    case concurrent(priority: TaskPriority?, parallellism: Int)

    public static let concurrent: AsyncIterationMode = concurrent(
        priority: nil, parallellism: ProcessInfo.processInfo.processorCount)
}

extension Sequence where Element: Sendable {
    nonisolated public func asyncForEach(
        mode: AsyncIterationMode = .concurrent,
        _ operation: @isolated(any) @escaping (borrowing Element) async throws -> Void
    ) async rethrows {
        switch mode {
        case .serial:
            for element in self {
                try await operation(element)
            }
        case .concurrent:
            _ = try await asyncMap(mode: mode, operation)
        }
    }
}

extension Sequence where Element: Sendable {
    public func asyncMap<NewElement: Sendable>(
        mode: AsyncIterationMode = .concurrent,
        _ transform: @isolated(any) @escaping (borrowing Element) async throws -> NewElement
    ) async rethrows -> [NewElement] {
        switch mode {

        case .serial:
            var result: [NewElement] = []
            result.reserveCapacity(underestimatedCount)
            for element in self {
                result.append (try await transform(element))
            }
            return result

        case let .concurrent(priority, paralellism):
            return try await withThrowingTaskGroup(of: (Int, NewElement).self) { group in
                var i: Int = 0
                var iterator: Self.Iterator = self.makeIterator()
                var results: [NewElement?] = [NewElement?]()
                results.reserveCapacity(underestimatedCount)

                func submitTask() throws {
                    try Task.checkCancellation()
                    if let element = iterator.next() {
                        results.append(nil)
                        group.addTask(priority: priority) { [i] in (i, try await transform(element)) }
                        i += 1
                    }
                }

                // add initial tasks
                for _ in 0..<paralellism { try submitTask() }

                // submit more tasks, as each one completes, until we run out of work
                while let (index, result) = try await group.next() {
                    results[index] = result
                    try submitTask()
                }

                return results.compactMap { $0 }
            }
        }
    }
}  */

public enum AsyncIterationMode: Sendable {
    /// Serial iteration performs each step in sequence, waiting for the previous one to complete before performing the next.
    case serial
    /// Concurrent iteration performs all steps in parallell, and resumes execution when all opeations are done.
    /// When applied to `asyncMap`, the results are returned in the original order.
    case concurrent(priority: TaskPriority?, parallellism: Int)

    public static let concurrent: AsyncIterationMode = concurrent(
        priority: nil, parallellism: ProcessInfo.processInfo.processorCount)
}

extension Sequence {
    public func asyncForEach(
        mode: AsyncIterationMode = .concurrent,
        _ operation: @escaping @isolated(any) (Element) async throws -> Void
    ) async rethrows {
        switch mode {
        case .serial:
            for element in self {
                try await { try await AsyncUnsafeThrowingIsolatedClosure(body: operation)(element) }()
            }
        case .concurrent:
            _ = try await asyncMap(mode: mode, operation)
        }
    }
}

extension Sequence {
    public func asyncMap<NewElement>(
        mode: AsyncIterationMode = .concurrent,
        _ transform: @escaping @isolated(any) (Element) async throws -> NewElement
    ) async rethrows -> [NewElement] {
        let closure = AsyncUnsafeThrowingIsolatedClosure<Self.Element, NewElement>(body: transform)

        switch mode {

        case .serial:
            var result: [NewElement] = []
            for element in self {
                result.append(try await { try await closure(element) }())
            }
            return result

        case let .concurrent(priority, parallellism):
            return try await withThrowingTaskGroup(
                of: (Int, UncheckedSendable<NewElement>).self
            ) {
                group in
                var i: Int = 0
                var iterator: Self.Iterator = self.makeIterator()
                var results: [NewElement?] = [NewElement?]()
                results.reserveCapacity(underestimatedCount)

                func submitTask() throws {
                    try Task.checkCancellation()
                    if let element = iterator.next() {
                        results.append(nil)
                        let element = UncheckedSendable(element)
                        group.addTask(priority: priority) { [i, element, closure] in
                            return try await (i, closure.unsafeReturn(input: element.getValue()))
                        }
                        i += 1
                    }
                }

                // add initial tasks
                for _ in 0..<parallellism { try submitTask() }

                // submit more tasks, as each one completes, until we run out of work
                while let (index, result) = try await group.next() {
                    results[index] = result.getValue()
                    try submitTask()
                }

                return results.compactMap { $0 }
            }
        }
    }
}

func withCancellingContinuation<T>(
    operation: (CheckedContinuation<T, Error>) -> Void,
    onCancel handler: @Sendable () -> Void
) async throws -> T {
    try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            operation(continuation)
        }
    } onCancel: {
        handler()
    }
}

@inlinable
internal func debugOnly(_ body: () -> Void) {
    assert(
        {
            body()
            return true
        }())
}

final class Point {}

struct GlobalActorValueType: @unchecked Sendable {
    @CustomActor var point: Point

    nonisolated let flag: Bool = false

    @MainActor let counter: Int

    @MainActor static var polygon: [Point] = []

    @CustomActor init(point: Point = Point(), counter: Int) {
        self.point = point
        self.counter = counter
    }

}

/* extension GlobalActorValueType {
    @CustomActor init(point: Point = Point(), counter: Int) async {
        self.point = point
        self.counter = await MainActor.run { counter }
    }
} */

#if swift(<6.0) || compiler(<6)
    func unsafe(@_unsafeMainActor @_unsafeSendable _: @escaping () -> Void) {}
#else
    @preconcurrency func unsafe( /* @preconcurrency  */_: () -> Void) {}
#endif

@_unsafeInheritExecutor func unsafeInheritExecutor() async {
    print(#function)
}

#if $ClosureIsolation || hasFeature(ClosureIsolation)
    func old(@_inheritActorContext _: @Sendable @isolated(any) () -> Void) {}

// func new(@inheritsIsolation _: @Sendable @isolated(any) () -> Void) {}
#endif

func isolatedTo(_: isolated (any Actor), _ ops: () -> Void) {
    ops()
}

#if $IsolatedAny || hasFeature(IsolatedAny) || hasAttribute(isolatedAny)
    func isolatedAny(_ ops: @escaping @isolated(any) () -> Void) {
        let isolation = ops.isolation
        Task(executorPreference: globalConcurrentExecutor) {  // [isolated isolation /* or self in actors */] in
            _ = isolation
            print("waking")
            await ops()
            print("finished")
        }
    }
#endif

#if hasAttribute(allowFeatureSuppression) || hasFeature(OptionalIsolatedParameters)
    @_alwaysEmitIntoClient
    @_allowFeatureSuppression(OptionalIsolatedParameters)
    func measure(isolation: isolated (any Actor)? = #isolation, _ work: () async -> Void) async
        -> Duration
    {
        await ContinuousClock().measure(isolation: isolation) {
            await work()
        }
    }
#endif

#if swift(>=5.3) && $RetroactiveAttribute
    @_disallowFeatureSuppression(RetroactiveAttribute)
    extension String: @retroactive Identifiable {
        public var id: String { self }
    }
#endif

struct CompHand {
    @AddCompletionHandler("HAND")
    func comp_hand() async -> String {
        ""
    }
}

struct MoveOnlyBox<T: ~Copyable>: ~Copyable {
    var inside: T?
    // deinit {}
}

// Deinitializer cannot be declared in generic struct 'MoveOnlyBox' that conforms to 'Copyable'
// Deinit is declared
// extension MoveOnlyBox: Copyable where T: Copyable {}

extension MoveOnlyBox where T: ~Copyable {
    /* var consumeGetIt: T? {
        consuming get {
            let inside_ = consume inside
            // that consume self or discard self
            return inside_
        }
    } */

    consuming func consumeGetIt() -> T? {
        let ins = consume inside  // Cannot partially consume 'self' when it has a deinitializer
        return ins
    }

    /*
    // Can only 'discard' type 'MoveOnlyBox<T>' if it contains trivially-destroyed stored properties at this timeSourceKit
    // Type 'T?' cannot be trivially destroyed

    consuming func end() {
        discard self
    }
     */
}

enum MoveOnlyEnum: ~Copyable {
    case a, b, c
}

func consumingGet() {
    let box = MoveOnlyBox(inside: MoveOnlyEnum.b)
    _ = box.consumeGetIt()
}
