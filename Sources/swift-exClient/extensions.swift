import CXX_Thread
import Foundation

extension TaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, operation: @escaping @Sendable (T) async -> ChildTaskResult,
        value: @autoclosure @escaping () -> T
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension ThrowingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, operation: @escaping @Sendable (T) async -> ChildTaskResult,
        value: @autoclosure @escaping () -> T
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension ThrowingDiscardingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, value: @autoclosure @escaping () -> T,
        operation: @escaping @Sendable (T) async -> Void
    ) {
        self.addTask(priority: priority) {
            await operation(value())
        }
    }
}

extension DiscardingTaskGroup {

    mutating func addTask<T: Sendable>(
        priority: TaskPriority? = nil, value: @autoclosure @escaping () -> T,
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
            job.runSynchronously(on: .sharedSampleExecutor)
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
    swift_task_enqueueGlobal_hook = { job, original in
        print("enqueueGlobal")
        original(job)
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
