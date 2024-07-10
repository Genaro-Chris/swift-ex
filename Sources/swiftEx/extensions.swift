import CXX_Thread
import Foundation
import Hook

extension TaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, operation: @escaping @Sendable (T) async -> ChildTaskResult,
        value: @autoclosure @escaping @Sendable () -> T
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension ThrowingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, operation: @escaping @Sendable (T) async -> ChildTaskResult,
        value: @autoclosure @escaping @Sendable () -> T
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension ThrowingDiscardingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, value: @autoclosure @escaping @Sendable () -> T,
        operation: @escaping @Sendable (T) async -> Void
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension DiscardingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, value: @autoclosure @escaping @Sendable () -> T,
        operation: @escaping @Sendable (T) async -> Void
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

let queue = SingleThread.create()

/* @_silgen_name("swift_task_enqueueMainExecutor")
func _enqueueMain(_ job: UnownedJob) {
    var job = consume job
    MyMainActor.queue.submit(&job) { job in
        print("Submitted task")
        let job = job.loadUnaligned(as: UnownedJob.self)
        job.runSynchronously(on: MyMainActor.sharedUnownedExecutor)
    }
} */

@globalActor
final actor MyMainActor: GlobalActor, SerialExecutor {
    static let shared: MyMainActor = MyMainActor()

    let queue = SingleThread.create()

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        asUnownedSerialExecutor()
    }

    nonisolated func enqueue(_ job: consuming ExecutorJob) {
        var job = UnownedJob(job)
        //_enqueueMain(job)
        queue.submit(&job) { jobPtr in
            print("Main")
            let job = jobPtr.load(as: UnownedJob.self)
            job.runSynchronously(on: MyMainActor.sharedUnownedExecutor)
        }
    }

    static var sharedUnownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: shared)
    }

    nonisolated func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
@MainActor
func someMainActorFunc() async {
    print("Main actor function")
}

// doesn't work
func play1() async throws {
    await MainActor.run {
        swift_task_enqueueGlobal_hook = { job, original in
            print("enqueueGlobal")
            original(job)
        }
    }
    /* swift_task_enqueueGlobal_hook = { job, original in
    print("enqueueGlobal")
    original(job)
} */
    /* // doesn't work
swift_task_enqueueMainExecutor_hook = { job, original in
    print("enqueueMainExecutor")
    //original(job)
    let job = unsafeBitCast(job, to: UnownedJob.self)
    _enqueueMain(job)
} */

    Task { @MainActor in
        print("Main actor task 1")
    }

    Task.detached { @MainActor in
        print("Main actor task 2")
    }

    Task.detached {
        print("Non main actor task")
    }

    await Task.detached {
        await someMainActorFunc()
    }.value

}

@rethrows
protocol RethrowingProtocol {
    associatedtype Value
    var value: Value { get set }
    func getValue() throws -> Value
    mutating func setValue<T>(with: (inout Value) throws -> T) rethrows -> T
}

extension RethrowingProtocol {
    /* func getValue() throws -> Value {
        return value
    } */

    mutating func setValue<T>(with: (inout Value) throws -> T) rethrows -> T {
        print("Protocol Impl")
        return try with(&self.value)
    }
}

struct SampleStruct<T>: RethrowingProtocol {
    var value: T
    func getValue() -> T {
        return value
    }

    mutating func setValue<U>(with: (inout T) throws -> U) rethrows -> U {
        print("Struct Impl")
        return try with(&self.value)
    }
}

func useRethrowProto() {
    print("@rethrows protocol")
    do {
        var sample: some RethrowingProtocol = SampleStruct(value: UUID())
        print("\(try sample.getValue())")
        // Member 'setValue' cannot be used on value of type 'any RethrowingProtocol';
        // consider using a generic constraint instead
        // SourceKit existential-member-access-limitations
        // var sample: any RethrowingProtocol
        /* sample.setValue { value in

        } */
        // try is complulsory because it from a rethrowing protocol
        try sample.setValue { value in
            print(type(of: value))
        }
        var sample2 = SampleStruct(value: "Message")
        print("\(sample2.getValue())")
        /* 
            try
            // No need for try 
        */sample2.setValue { value in
            print(type(of: value))
        }
    } catch {
        print(error)
    }
}
