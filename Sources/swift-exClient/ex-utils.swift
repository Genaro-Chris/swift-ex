import Foundation

public enum AsyncIterationMode: Sendable {
    /// Serial iteration performs each step in sequence, waiting for the previous one to complete before performing the next.
    case serial
    /// Concurrent iteration performs all steps in parallell, and resumes execution when all opeations are done.
    /// When applied to `asyncMap`, the results are returned in the original order.
    case concurrent(priority: TaskPriority?, parallellism: Int)

    public static let concurrent = concurrent(
        priority: nil, parallellism: ProcessInfo.processInfo.processorCount)
}

extension Sequence where Element: Sendable {
    public func asyncForEach(
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

    public func asyncMap<NewElement: Sendable>(
        mode: AsyncIterationMode = .concurrent,
        _ transform: @isolated(any) @escaping (borrowing Element) async throws -> NewElement
    ) async rethrows -> [NewElement] {
        switch mode {

        case .serial:
            var result: [NewElement] = []
            result.reserveCapacity(underestimatedCount)
            for element in self {
                result.append(try await transform(element))
            }
            return result

        case let .concurrent(priority, paralellism):
            return try await withThrowingTaskGroup(of: (Int, NewElement).self) { group in
                var i = 0
                var iterator = self.makeIterator()
                var results = [NewElement?]()
                results.reserveCapacity(underestimatedCount)

                func submitTask() throws {
                    try Task.checkCancellation()
                    if let element = iterator.next() {
                        results.append(nil)
                        group.addTask(priority: priority) { [i] in (i, try await transform(element))
                        }
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

@_unsafeInheritExecutor func unsafeInheritExecutor() async {}

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
        Task(executorPreference: globalConcurrentExecutor) { // [isolated isolation /* or self in actors */] in
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
    // @_disallowFeatureSuppression(RetroactiveAttribute)
    extension String: @retroactive Identifiable {
        public var id: String { self }
    }
#endif
