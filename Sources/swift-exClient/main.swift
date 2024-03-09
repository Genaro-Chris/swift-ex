import CXX_Thread
import CustomExecutor
import Foundation
import Interface
// import Observation
import SwiftLib
import SwiftWithCXX
import _Differentiation
import cxxLibrary

extension Thread {
    var id: String {
        String(getThreadID())
    }
}


do {
    typealias OpaqueJob = UnsafeMutableRawPointer
    typealias EnqueueOriginal = @convention(c) (OpaqueJob) -> Void
    typealias EnqueueHook = @convention(c) (OpaqueJob, EnqueueOriginal) -> Void

    let handle = dlopen(nil, 0)
    let enqueueGlobal_hook_ptr = dlsym(handle, "swift_task_enqueueGlobal_hook")!
        .assumingMemoryBound(to: EnqueueHook.self)

    enqueueGlobal_hook_ptr.pointee = { opaque_job, original in
        //print("simple example succeeded")
        //original(opaque_job)

        // In real implementation, move job to your workloop
        // and eventually run:

        let job = unsafeBitCast(opaque_job, to: UnownedJob.self)
        //CustomGlobalExecutor.shared.enqueue(job)
        job.runSynchronously(on: .generic)
    }
}

        Task.detached {
            //exit(0)
            print("Example task detached")
        }

        let task = Task.detached {
            try await withTaskCancellationHandler {
                print("About to sleep for 3 secs")
                try await Task.sleep(for: .seconds(3))
            } onCancel: {
                print("oops cancelled")
            }
        }

        task.cancel()

        try await Task.sleep(for: .seconds(2))

        //dispatchMain()

        #if hasFeature(BodyMacros)
            print("Has Body Macros")
        //@Logged

        #endif

        withUnsafeTemporaryAllocation(of: Int.self, capacity: 2, { _ in })

        print("Multithreaded \(Thread.isMultiThreaded())")

        #if hasFeature(GenerateBindingsForThrowingFunctionsInCXX)
            print("GenerateBindingsForThrowingFunctionsInCXX exists in this compiler")
        #endif

        #if $TypedThrows
            do {
                try throwing_func()
            } catch {
                print("Caught \(error)")
            }
        #endif

        do {
            let pool = ThreadPool.create(CPU_Count)
            for _ in 1 ... 20 {
                pool.submit {
                    print(
                        "ThreadPool \(Thread.current.name ?? "Unknown") with id \(Thread.current.id) and description \(Thread.current.description)"
                    )
                }
            }
            Thread.sleep(forTimeInterval: 4)
        }

        let v = V< >()

        print(v, type(of: v))

        forValueType(value: 122)
        //forValueType(value: ThreadPool.create(2))

        _ = downcast(ExPerson() as AnyObject, to: ExPerson.self)

        var angle = Angle()
        angle.radians = 43.21
        print("\(angle.points)\n\(angle.radians)")

        example("dew", 1, 23.33, Float(60), tuple_pack: ("dew", 1, 23.33, Float(60)))

        var person: PersonDetail? = PersonDetail(details: Ex(age: 18, name: "Adam"))

        person?.details.name = "Changed"
        let person1 = person
        let person2 = person

        print("Person \(person!)")

        print("Person1 \(person1!)")

        print("Person2 \(person2!)")

        person2?.details()

        person2?.details.age = 25

        person1?.details.name = "Obi"

        person2?.details.name = "Person2"

        print("Person1 \(person1!)")

        print("Person2 \(person2!)")

        print("Person \(person!)")

        print("Set person to nil")

        person = nil

        if let person1, let person2 {
            print("Person1 \(person1)")

            print("Person2 \(person2)")
        }

        let ex: NonCopyWithGen<UInt> = NonCopyWithGen(item: 23)
        ex(1, 2, 3)

        #if $TransferringArgsAndResults || hasFeature(TransferringArgsAndResults)

            let n = OClass()
            extendLife(n)
            await CustomActor.shared.take(n)
            print(n)
        #endif

        Task.init(_executorPreference: globalConcurrentExecutor) {
            print("\(Thread.current.name ?? "unknown")")
        }

        Task._detached(_executorPreference: globalConcurrentExecutor) {
            print("\(Thread.current.name ?? "unknown")")
        }

        async let _ = _withTaskExecutorPreference(
            globalConcurrentExecutor
        ) {
            await withDiscardingTaskGroup { group in
                for _ in 1 ... 5 {
                    group.addTask {
                        print("\(Thread.current.name ?? "unknown")")
                    }
                }
                group._addTask(executorPreference: globalConcurrentExecutor) {}
            }

            withUnsafeCurrentTask { currentTask in
                guard let currentTask else {
                    return
                }
                _ = currentTask._unownedTaskExecutor
            }

        }

        Task.detached {  // @MainActor in
            if _taskIsOnExecutor(MainExecutor.shared) {
                print(
                    "Task is executing on \(type(of: MainExecutor.shared)) which is \(Thread.current.name ?? "unknown")"
                )
            }
        }

        let new = NewActor()
        await withDiscardingTaskGroup { group in
            let actor = CustomActor()
            for priority in TaskPriority.allCases {
                group.addTask(priority: priority) {
                    Task { @CustomActor in
                        async let _ = new.append(value: 1)
                    }
                    await new.append(value: 1)
                    await actor.example()
                }
            }
        }

        print("After \(await new.counter)")

        @_eagerMove
        let resultInt = if Bool.random() {
            print("Then statement")
            then 0
        } else {
            print("Then")
            then 1
        }

        print(resultInt)

        dou()

        print("Random number is: ", createUniformPseudoRandomNumberGenerator(1.0, 90.5))

        print("Hello World from Swift")

        hello_world("Hello world from C++")

        var user = ConceptUser("Concept Impl")

        print("\(type(of: user)) has padding \(hasPadding(user))")

        usesOnlyConcept(user)

        user.Print("msg: std.string")

        // keywords consume, borrowing, consuming, copy, __shared, __owned,
        usesConcept(copy user)

        let cstr = returns_string()

        print(cstr)

        let newStr: std.string = "Are you sure?"

        usesConcept(newStr)

        do {
            var value = 123.5
            let val = special_move(&value)
            print(val.pointee)
            //_ = consume value
        }

        let new_val = special_move(&user)

        var specialValue = SpecialType()

        print(specialValue)

        let new_val1 = special_move(&specialValue)

        usesConcept(1345)

        print("About to use moved value")

        print(user, specialValue)

        print(new_val.pointee, new_val1.pointee)

        print("Done using moved value")

        try await closure {
            try await Task.sleep(for: .seconds(5))
            print("Closure")
        }

        print("After")
        //await CustomActor.init().example()

        let adam = Person(name: "Adam", age: 25)

        print("Adam \(adam)")
        let moved = ExPerson()

        // __swift_interopStaticCast(from: Int)

        _ = consume moved

        let pType = Person.self

        let metatype: Any.Type = pType

        print(existential(pType))

        print(_openExistential(metatype, do: existential))

        returnLastExpr()

        // print(existential(_openExistential(metatype, do: existential)))

        // print(existential(metatype)) Error:

    }
}
