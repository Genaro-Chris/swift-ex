import CXX_Thread
@_exported import Distributed
import DistributedHTTPActorSystem
import Foundation

extension ThreadPool {
    consuming func stopAllWork() {
        self.stop()
    }
}

extension SingleThreadedPool {
    consuming func stopAllWork() {
        self.stop()
    }
}

public final class CustomGlobalExecutor: SerialExecutor {

    public let customQueue = ThreadPool.create(CPU_Count)

    public func enqueue(_ job: consuming ExecutorJob) {
        var job = UnownedJob(job)
        /* withUnsafePointer(to: CustomGlobalExecutor.sharedUnownedExecutor) { pointer in
           customQueue.submitTaskWithExecutor(&job, pointer, handler_global_exe(_:_:))
        } */
        CXX_Thread.RunOnce(handler_global(_:), &job)
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    deinit {
        customQueue.stopAllWork()
    }
}

extension CustomGlobalExecutor {

    public static let shared: CustomGlobalExecutor = .init()

    public static var sharedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: shared)
    }

}

extension UnownedSerialExecutor {
    public static var generic: Self {
        CustomGlobalExecutor.sharedUnownedExecutor
        //unsafeBitCast((0, 0), to: self)
    }
}

extension TaskType: CaseIterable {
    public static var allCases: [TaskType] {
        [.Execute, .Stop]
    }
}

let task = Task_.init(type: .Execute, task: .init(), arguments: .init(.init()))

/// Example of a custom Executor of an actor
public final class CustomExecutor: SerialExecutor {

    enum ExecutorKind {
        case distributedKind, normalKind
    }

    init(kind: ExecutorKind) {
        self.kind = kind
    }

    let kind: ExecutorKind

    let customQueue = SingleThreadedPool.create()

    public func enqueue(_ job: consuming ExecutorJob) {
        var job = UnownedJob(job)
        var kind = kind
        customQueue.submitTaskWithExecutor(&job, &kind) { job, kind in
            let job = job.load(as: UnownedJob.self)
            let kind = kind.load(as: CustomExecutor.ExecutorKind.self)
            let executor =
                switch kind {
                    case .distributedKind:
                        CustomExecutor.sharedDistributedUnownedExecutor
                    case .normalKind:
                        CustomExecutor.sharedUnownedExecutor
                }
            job.runSynchronously(on: executor)
        }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

public func handler_global_exe(_ job: UnsafeRawPointer, _ executor: UnsafeRawPointer) {
    let job = job.load(as: UnownedJob.self)
    let executor = executor.load(as: UnownedSerialExecutor.self)
    job.runSynchronously(on: executor)
}

private func handler_global(_ job: UnsafeRawPointer) {
    let job = job.load(as: UnownedJob.self)

    job.runSynchronously(on: CustomGlobalExecutor.sharedUnownedExecutor)
}

extension CustomExecutor {

    fileprivate static let sharedDistributed: CustomExecutor = .init(
        kind: ExecutorKind.distributedKind)

    fileprivate static let shared: CustomExecutor = .init(kind: ExecutorKind.normalKind)

    public static var sharedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: shared)
    }

    public static var sharedDistributedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: sharedDistributed)
    }
}

@dynamicMemberLookup
public protocol SpecialActor: DistributedActor, Codable {
    subscript<T>(dynamicMember member: ReferenceWritableKeyPath<Self, T>) -> T { get set }
}

extension SpecialActor {
    public subscript<T>(dynamicMember member: ReferenceWritableKeyPath<Self, T>) -> T {
        get {
            print("Called get")
            return self[keyPath: member]
        }
        set {
            print("Called set")
            self[keyPath: member] = newValue
        }
        _modify {
            print("Called modify and about to yield")
            yield &self[keyPath: member]
            print("Yielded already")

        }
    }

    public distributed func health_check() {
        print("Health check for \(self.id)")
    }

    public distributed func execute(body: (ID) -> Void) {
        body(self.id)
    }
}

public protocol ServerActor: DistributedActor {
    distributed func remove_with_id(
        id: Self.ID
    ) async throws
}
