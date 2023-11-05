import CXX_Thread
@_exported import Distributed
import DistributedHTTPActorSystem
import Foundation

/// Example of a custom Executor of an actor
public final class CustomExecutor: SerialExecutor {

    //let customQueue = CXX_Thread.create { }

    public func enqueue(_ job: consuming ExecutorJob) {
        var job = UnownedJob(job)
        CXX_Thread.RunOnce(handler, &job)
        //customQueue.run(handler(_:), &job)
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

private func handler(_ job: UnsafeRawPointer) {
    let job = job.load(as: UnownedJob.self)
    job.runSynchronously(on: CustomExecutor.sharedUnownedExecutor)
}

extension CustomExecutor {

    fileprivate class var sharedDistributed: Self {
        Self()
    }

    fileprivate static let shared: CustomExecutor = .init()

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
