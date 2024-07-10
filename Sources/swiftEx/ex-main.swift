/* @preconcurrency */ import CXX_Thread
internal import CustomExecutor
import Foundation
import Hook
import Interface
import SwiftWithCXX
import _Differentiation
import cxxLibrary

import class ThreadPool.ThreadPool
import class ThreadPool.WaitGroup

// import SwiftBridging
#if canImport(Observation) && os(macOS)
    import Observation
#endif

/* nonisolated(unsafe) */ let handleG: CXX_ThreadPool = CXX_ThreadPool.create(1)

func handleTask(job: UnsafeRawPointer, _ body: @escaping @convention(c) (UnsafeRawPointer) -> Void)
{
    handleG.submit(job, body)
}
@main
enum Program {

    @TaskLocal static var local: String = ""

    static func main() async throws {
        do {
            typealias OpaqueJob = UnsafeMutableRawPointer
            typealias EnqueueOriginal = @convention(thin) (OpaqueJob) -> Void
            typealias EnqueueHook = @convention(thin) (OpaqueJob, EnqueueOriginal) -> Void

            let handle: UnsafeMutableRawPointer? = dlopen(nil, 0)
            let enqueueGlobal_hook_ptr: UnsafeMutablePointer<EnqueueHook> = dlsym(
                handle, "swift_task_enqueueGlobal_hook")!
                .assumingMemoryBound(to: EnqueueHook.self)

            enqueueGlobal_hook_ptr.pointee = { opaque_job, original in
                //print("simple example succeeded")
                // original(opaque_job)

                // In real implementation, move job to your workloop
                // and eventually run:

                // <unknown>:0: error: circular reference
                // <unknown>:0: note: through reference here
                // swift 6.0
                let job: UnownedJob = unsafeBitCast(opaque_job, to: UnownedJob.self)
                CustomGlobalExecutor.sharedG.enqueue(job)

                /* handleTask(job: opaque_job) {
                    unsafeBitCast($0, to: UnownedJob.self).runSynchronously(
                        on: UnownedSerialExecutor.generic)
                } */
            }
        }

        foo1()

        Task.detached {
            //exit(0)
            $local.withValue("Local to Detached") {
                print(local)
            }
            print("Example task detached")
            print(
                "Task.detached \(Thread.current.name ?? "Unknown") with id \(Thread.current.id) and description \(Thread.current.description)"
            )
        }

        let task: Task<(), any Error> = Task.detached {
            try await withTaskCancellationHandler {
                print("About to sleep for 3 secs")
                try await Task.sleep(for: .seconds(3))
            } onCancel: {
                print("oops cancelled")
            }
        }

        task.cancel()

        printMem(CustomActor.self)

        try await Task.sleep(for: .seconds(2))

        print(getThreadID())

        // dispatchMain() // same as exit(1)

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

        var model: Perceptron = Perceptron(weight: SIMD2<Float>.init(x: 1, y: 2), bias: 4.7)
        let andGateData: [(x: SIMD2<Float>, y: Float)] = [
            (x: [0, 0], y: 0),
            (x: [0, 1], y: 0),
            (x: [1, 0], y: 0),
            (x: [1, 1], y: 1),
        ]

        for _ in 0..<20 {
            let (loss, 𝛁loss) = valueWithGradient(at: model) { model -> Float in
                var loss: Float = 0
                for (x, y) in andGateData {
                    let ŷ = model(x)
                    let error = y - ŷ
                    loss = loss + error * error / 2
                }
                return loss
            }
            print(loss)
            model.weight -= 𝛁loss.weight * 0.02
            model.bias -= 𝛁loss.bias * 0.02
        }

        do {
            let pool: CXX_ThreadPool = CXX_ThreadPool.create(4)
            let futex = FutexLock.create()
            class Counter {
                private(set) var count: Int = 0
                func increment() { count += 1 }
            }
            let counter = Counter()
            let futexUn = Unmanaged.passRetained(futex)
            let counterUn = Unmanaged.passUnretained(counter)
            for _ in 1...10 {
                pool.submitTaskWithExecutor(futexUn.toOpaque(), counterUn.toOpaque()) {
                    lock, count in
                    let lock = Unmanaged<FutexLock>.fromOpaque(lock).retain().takeRetainedValue()
                    let count = Unmanaged<Counter>.fromOpaque(count).takeUnretainedValue()
                    lock.locked {
                        count.increment()
                    }
                    print(
                        "ThreadPool \(Thread.current.name ?? "Unknown") and description \(Thread.current.description)"
                    )
                }
            }

            pool.waitForAll()
            print("Counter: \(counter.count)")
        }

        Task { nonisolated in
            print("Running Task { nonisolated } on \(Thread.current.name ?? "Unknown")")
        }

        // Task { [isolated isolation] in print("Running Task [isolated isolation] on \(Thread.current.name ?? "Unknown")") }

        try await [Int](repeating: 0, count: 100).asyncForEach(
            mode: .concurrent(priority: .high, parallellism: 5)
        ) { (_) in // Sending main actor-isolated value of type '(Int) async throws -> ()' with later accesses to nonisolated context risks causing data races
            try await Task.sleep(for: .microseconds(100))
        }

        #if DEBUG
            print("Only in debug build with DEBUG MACRO")
        #endif

        debugOnly {
            print("Only in debug build")
        }

        let task1: Task<Int, any Error> = Task.detached {
            try await withCancellingContinuation { cont in
                Thread.sleep(forTimeInterval: 3)
                cont.resume(returning: 200)
            } onCancel: {
                print("Runs when cancelled")
            }
        }

        try await Task.sleep(for: .seconds(1))

        task1.cancel()

        print(try await task1.value)

        useV()  // V< >()

        forValueType(value: 122)
        //forValueType(value: ThreadPool(2))

        _ = product(b: 123)

        _ = downcast(ExPerson() as AnyObject, to: ExPerson.self)

        #if SWIFTSETTINGS
            print("SWIFTSETTINGS")
        #endif

        #if EXAMPLESETTINGS
            print("EXAMPLESETTINGS")
        #endif

        consumingGet()

        var angle: Angle = Angle()
        angle.radians = 43.21
        print("\(angle.points)\n\(angle.radians)")

        example("dew", 1, 23.33, Float(60), tuple_pack: ("dew", 1, 23.33, Float(60)))

        var person: PersonDetail? = PersonDetail(details: Ex(age: 18, name: "Adam"))

        person?.details.name = "Changed"
        let person1: PersonDetail? = person
        let person2: PersonDetail? = person

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

        _ = SensitiveStruct()

        // takeOnlyConst(onlyConst) // expect a compile-time constant literal

        takeOnlyConst(23)

        let dto: DTOStruct = DTOStruct(
            id: UUID(), createdAt: .now, title: "String", description: "String", items: [1, 23, 3])
        print(dto)

        let subscripter: SubscriptClass = SubscriptClass()

        _ = subscripter[]
        let _: Int = SubscriptClass[]
        let _: Float = SubscriptClass[]

        takeOnlyConst(12)

        /*
        // compiler bug because ~Copyable & @dynamicCallable is a bug
        let ex: NonCopyWithGen<UInt> = NonCopyWithGen(item: 23)
        ex(1, 2, 3)
        */

        let ex: CopyWithGen<UInt> = CopyWithGen(item: 23)
        ex(1, 2, 3)

        #if hasFeature(InferSendableFromCaptures)
            let _: @Sendable () async -> Void = CustomActor.shared.example
            let _: @Sendable (Perceptron) -> Float = \Perceptron.bias
        #endif

        let _: (OClass) -> Int = \OClass.age

        let _: (BaseClass) -> SubClass = \BaseClass.subClass

        #if $TransferringArgsAndResults || hasFeature(TransferringArgsAndResults)
            let _: (_: /* inout, borrowing, consuming */ transferring OClass) -> transferring OClass
            let n: OClass = OClass()
            extendLife(n)
            await CustomActor.shared.take(n)
        // Concurrent usage of non-sendable type
        /* print(n) */
        #endif

        Task.init(executorPreference: globalConcurrentExecutor) {
            print("global \(Thread.current.name ?? "unknown")")
        }

        Task.detached(executorPreference: CustomThreadGlobalExecutor.sharedT) {
            print("custom global thread \(Thread.current.name ?? "unknown")")
        }

        _ = await GlobalActorValueType(point: Point(), counter: 233)

        async let _ = withTaskExecutorPreference(
            CustomGlobalExecutor.sharedG
        ) {
            await withDiscardingTaskGroup { group in
                for _ in 1...5 {
                    group.addTask {
                        print("\(Thread.current.name ?? "unknown")")
                    }
                }
                group.addTask(executorPreference: globalConcurrentExecutor) {}
            }

            withUnsafeCurrentTask { currentTask in
                guard let currentTask else {
                    return
                }
                _ = currentTask.unownedTaskExecutor
            }

        }

        print("Function / Body Macros")

        aboutToTrace()

        _ = try await f(a: 3, b: "f")

        print("Function / Body Macros end")

        /* CustomGlobalExecutor.sharedG.submit {
            print("\(Thread.current.name ?? "unknown")")
        } */

        /* let wg: DispatchGroup = DispatchGroup()
        wg.enter()
        let un: Unmanaged<DispatchGroup> = Unmanaged.passUnretained(wg)
        handleG.submit(un.toOpaque()) { wG in
            ThreadPool.globalPool.submit {
                print("Using Unmanaged")
                print("\(Thread.current.name ?? "unknown")")
                Unmanaged<DispatchGroup>.fromOpaque(wG).takeUnretainedValue().leave()
            }
        }

        // wg.wait()
        ThreadPool.globalPool.poll()

        handleG.waitForAll() */

        Task.detached { /* @CustomActor in */
            // @MainActor in
            await withTaskExecutorPreference(CustomGlobalExecutor.sharedG) {
                if _taskIsOnExecutor(CustomGlobalExecutor.sharedG) {
                    print(
                        "Task is executing on \(type(of: CustomGlobalExecutor.sharedG)) which is \(Thread.current.name ?? "unknown")"
                    )
                }
            }

        }

        let new: NewActor = NewActor()
        await withDiscardingTaskGroup { group in
            let actor: CustomActor = CustomActor()
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

        let _ /* tuple */: NonCopyableTuplePair<String, NonCopyableEnum> = ("Noncopyable Tuple", NonCopyableEnum.one)

        
        /* 
        
        // Can't use MoveOnlyTuples in any way
        let (old_, _) = tuple

        print(old_)

        print(type(of: tuple))

        print(tuple.0)

        _ = tuple */

        useThen()  // use Then statement

        dou()

        lexy("Msg")

        useRethrowProto()

        await unsafeInheritExecutor()

        unsafe {
            print(#function, "unsafe")
        }

        #if compiler(>=5.3) && $StaticAssert
            print("Static Assert")
            #assert(true)
        #endif

        var ptr: Int = 0

        // Cannot use inout expression here; argument 'at' must be a pointer that outlives the call to 'noInout(at:)'
        // Implicit argument conversion from 'Int' to 'UnsafeMutablePointer<Int>' produces a pointer valid only for the duration of the call to 'noInout(at:)'
        // noInout(at: &ptr)
        withUnsafeMutablePointer(to: &ptr) { noInout(at: $0) }

        sendableFunc(1, 2.3, "", 32.4 as Float)

        print("Random number is: ", createUniformPseudoRandomNumberGenerator(1.0, 90.5))

        print("Hello World from Swift")

        helloWorld("Hello world from C++")

        var user: ConceptUser = ConceptUser("Concept Impl")

        main_actor_func {
            print("MainActor isolated closure in swift")
        }

        print("\(type(of: user)) has padding \(hasPadding(user))")

        usesOnlyConcept(user)

        user.Print("msg: std.string")

        let mainActorInstance: MainActorStruct = MainActorStruct(
            name: "MainActor isolated struct instance from c++")

        mainActorInstance.print_name()

        // keywords consume, borrowing, consuming, copy, __shared, __owned,
        usesConcept(copy user)

        let _: CXX_Any = CXX_Any(123)

        // _ = cxx_any.values

        let cstr: std.string = returns_string()

        print(cstr)

        let newStr: std.string = "Are you sure?"

        usesConcept(newStr)

        do {
            var value: Double = 123.5
            let val: UnsafeMutablePointer<Double> = special_move(&value)
            print(val.pointee)
            _ = consume value
        }

        let new_val: UnsafeMutablePointer<ConceptUser> = special_move(&user)

        var specialValue: SpecialType = SpecialType()

        print(specialValue)

        let new_val1: UnsafeMutablePointer<SpecialType> = special_move(&specialValue)

        usesConcept(1345)

        print("About to use moved value")

        print(user, specialValue)

        print(new_val.pointee, new_val1.pointee)

        print("Done using moved value")

        // Play with c++ noncopyable types and consuming, borrowing modifiers
        cxx_move()

        #if IsolatedAny || hasFeature(IsolatedAny) || hasAttribute(IsolatedAny)
            isolatedAny { @CustomActor in print("#isolatedAny isolated to CustomActor") }
        #endif

        #if IsolatedAny || hasFeature(IsolatedAny) || hasAttribute(IsolatedAny)
            isolatedAny { @CustomActor in
                print(
                    "#isolatedAny isolated to CustomActor hence accessing point \(GlobalActorValueType(point: Point(), counter: 0).point) without await"
                )
            }
            Task(executorPreference: CustomThreadGlobalExecutor.sharedT) {
                let gV: GlobalActorValueType = await GlobalActorValueType(
                    point: Point(), counter: 0)
                await CustomActor.run {
                    print(gV.point)
                }
            }
        #endif

        try await closure { nonisolated in  // weird bug in swift 6 swift 6 fix
            try await Task.sleep(for: .seconds(5))
            print("Closure")
        }

        print(typeErased())

        await isolatedTo(CustomActor.shared) { nonisolated in  // weird bug in swift 6 swift 6 fix
            print("#isolatedTo isolated to CustomActor")
        }

        #if hasAttribute(allowFeatureSuppression) || hasFeature(OptionalIsolatedParameters)
            let duration: Duration = await measure {
                try? await Task.sleep(for: .microseconds(100))
                print("#measure OptionalIsolatedParameters")
            }
            print("It took \(duration)")
        #endif

        let adam: Person = Person(name: "Adam", age: 25)

        print("Adam \(adam)")
        let moved: ExPerson = ExPerson()

        // __swift_interopStaticCast(from: Int)

        _ = consume moved

        // _resultDependsOnSelf
        _ = MethodModifiers().resultDependsOnSelf()

        // Noncopyable Generics, Borrowing switch, MoveOnlyPartialConsumption
        playWith()

        // Conditional Copyability
        print("Conditional Copyability")
        playWithCopy()

        // Destructing
        destructuredQuantityTuple()

        destructuredQuantity()

        destructuredApply()

        destructuredSwitch()

        let pType: Person.Type = Person.self

        let metatype: Any.Type = pType

        print(existential(pType))

        print(_openExistential(metatype, do: existential))  // calls existential(T.Type)

        print(existential(metatype))  // calls existential(_: Any.Type)

        #if $ImplicitLastExprResults && hasFeature(ImplicitLastExprResults)
            _ = returnLastExpr()
        #endif

        print(existential(_openExistential(metatype, do: existential)))

        print(existential(metatype))  // Error:

        measure("CXX_ThreadPool_globalPool_Wait_Unret") { _ in
            let group: WaitGroup = WaitGroup()
            let grp: UnsafeMutableRawPointer = Unmanaged.passUnretained(group).toOpaque()
            for _ in 1...1_000_000 {
                group.enter()
                CXX_ThreadPool.globalPool.submit(grp) { grp in
                    Unmanaged<WaitGroup>.fromOpaque(grp).takeUnretainedValue().done()
                }
            }
            group.waitForAll()
        }

        measure("CXX_ThreadPool_globalPool_Wait_Ret") { _ in
            let group: WaitGroup = WaitGroup()
            let grp: UnsafeMutableRawPointer = Unmanaged.passRetained(group).toOpaque()
            for _ in 1...1_000_000 {
                group.enter()
                CXX_ThreadPool.globalPool.submit(grp) { grp in
                    Unmanaged<WaitGroup>.fromOpaque(grp).retain().takeRetainedValue().done()
                }
            }
            group.waitForAll()
        }

        measure("CXX_threadpool_globalPool_Wait_Unret") { _ in
            let group: WaitGroup = WaitGroup()
            let grp: UnsafeMutableRawPointer = Unmanaged.passUnretained(group).toOpaque()
            for _ in 1...1_000_000 {
                group.enter()
                CXX_threadpool.global_pool.submit_with(grp) { grp in
                    Unmanaged<WaitGroup>.fromOpaque(grp).takeUnretainedValue().done()
                }
            }
            group.waitForAll()
        }

        measure("CXX_threadpool_global_pool_Wait_Ret") { _ in
            let group: WaitGroup = WaitGroup()
            let grp: UnsafeMutableRawPointer = Unmanaged.passRetained(group).toOpaque()
            for _ in 1...1_000_000 {
                group.enter()
                CXX_threadpool.global_pool.submit_with(grp) { grp in
                    Unmanaged<WaitGroup>.fromOpaque(grp).retain().takeRetainedValue().done()
                }
            }
            group.waitForAll()
        }

    }
}
