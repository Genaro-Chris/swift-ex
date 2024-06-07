import CXX_Thread
import CustomExecutor
import Foundation
import Hook
import Interface
import SwiftBridging
// import Observation
import SwiftWithCXX
import _Differentiation
import cxxLibrary

import class ThreadPool.ThreadPool
import class ThreadPool.WaitGroup

let handleG = CXX_ThreadPool.create(1)

func handleTask(job: UnsafeRawPointer, _ body: @escaping @convention(c) (UnsafeRawPointer) -> Void)
{
    handleG.submit(job, body)
}
@main
enum Program {

    @TaskLocal static var local = ""

    static func main() async throws {
        do {
            typealias OpaqueJob = UnsafeMutableRawPointer
            typealias EnqueueOriginal = @convention(thin) (OpaqueJob) -> Void
            typealias EnqueueHook = @convention(thin) (OpaqueJob, EnqueueOriginal) -> Void

            let handle = dlopen(nil, 0)
            let enqueueGlobal_hook_ptr = dlsym(handle, "swift_task_enqueueGlobal_hook")!
                .assumingMemoryBound(to: EnqueueHook.self)

            enqueueGlobal_hook_ptr.pointee = { opaque_job, original in
                //print("simple example succeeded")
                // original(opaque_job)

                // In real implementation, move job to your workloop
                // and eventually run:

                // <unknown>:0: error: circular reference
                // <unknown>:0: note: through reference here
                // swift 6.0
                let job = unsafeBitCast(opaque_job, to: UnownedJob.self)
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

        var model = Perceptron()  // (weight: SIMD2<Float>.init(x: 1, y: 2), bias: 4.7)
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
            let pool = CXX_ThreadPool.create(4)
            for _ in 1...20 {
                pool.submit {
                    print(
                        "ThreadPool \(Thread.current.name ?? "Unknown") with id \(Thread.current.id) and description \(Thread.current.description)"
                    )
                }
            }
            Thread.sleep(forTimeInterval: 4)
        }

        Task { nonisolated in
            print("Running Task { nonisolated } on \(Thread.current.name ?? "Unknown")")
        }

        // Task { [isolated isolation] in print("Running Task [isolated isolation] on \(Thread.current.name ?? "Unknown")") }

        try await [Int](repeating: 0, count: 100).asyncForEach(
            mode: .concurrent(priority: .high, parallellism: 5)
        ) { _ in
            try await Task.sleep(for: .microseconds(100))
        }

        #if DEBUG
            print("Only in debug build with DEBUG MACRO")
        #endif

        debugOnly {
            print("Only in debug build")
        }

        let task1 = Task.detached {
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

        let v = V< >()

        print(v, type(of: v))

        forValueType(value: 122)
        //forValueType(value: ThreadPool.create(2))

        _ = product(b: 123)

        _ = downcast(ExPerson() as AnyObject, to: ExPerson.self)

        #if SWIFTSETTINGS
            print("SWIFTSETTINGS")
        #endif

        #if EXAMPLESETTINGS
            print("EXAMPLESETTINGS")
        #endif

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

            let n = OClass()            
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
                for _ in 1 ... 5 {
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

        

        /* CustomGlobalExecutor.sharedG.submit {
            print("\(Thread.current.name ?? "unknown")")
        } */


        // <unknown>:0: error: circular reference
        // <unknown>:0: note: through reference here
        // swift 6.0
        let wg = DispatchGroup()
        wg.enter()
        let un = Unmanaged.passUnretained(wg)
        CXX_ThreadPool.create(1).submit(un.toOpaque()) { wG in
            ThreadPool.globalPool.submit {
                print("Using Unmanaged")
                print("\(Thread.current.name ?? "unknown")")
                Unmanaged<DispatchGroup>.fromOpaque(wG).takeUnretainedValue().leave()
            }
            ThreadPool.globalPool.poll()
            
        }

        wg.wait()
        
        Task.detached {  // @MainActor in
            if _taskIsOnExecutor(CustomGlobalExecutor.sharedG) {
                print(
                    "Task is executing on \(type(of: CustomGlobalExecutor.sharedG)) which is \(Thread.current.name ?? "unknown")"
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

        helloWorld("Hello world from C++")

        var user = ConceptUser("Concept Impl")

        main_actor_func {
            print("MainActor isolated closure in swift")
        }

        print("\(type(of: user)) has padding \(hasPadding(user))")

        usesOnlyConcept(user)

        user.Print("msg: std.string")

        let mainActorInstance = MainActorStruct(name: "MainActor isolated struct instance from c++")

        mainActorInstance.print_name()

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

        #if IsolatedAny || hasFeature(IsolatedAny) || hasAttribute(IsolatedAny)
            isolatedAny { @CustomActor in print("#isolatedAny isolated to CustomActor") }
        #endif

        #if IsolatedAny || hasFeature(IsolatedAny) || hasAttribute(IsolatedAny)
            isolatedAny { @CustomActor in
            print("#isolatedAny isolated to CustomActor hence accessing point \(GlobalActorValueType(point: Point(), counter: 0).point) without await") }
            Task(executorPreference: CustomThreadGlobalExecutor.sharedT) {
                let gV = await GlobalActorValueType(point: Point(), counter: 0)
                await CustomActor.run {
                    print(gV.point)
                }
            }
        #endif

        try await closure { nonisolated in // weird bug in swift 6 swift 6 fix
            try await Task.sleep(for: .seconds(5))
            print("Closure")
        }

        print(typeErased())

        await isolatedTo(CustomActor.shared) { nonisolated in // weird bug in swift 6 swift 6 fix
            print("#isolatedTo isolated to CustomActor")
        }

        #if hasAttribute(allowFeatureSuppression) || hasFeature(OptionalIsolatedParameters)
            let duration = await measure {
                try? await Task.sleep(for: .microseconds(100))
                print("#measure OptionalIsolatedParameters")
            }
            print("It took \(duration)")
        #endif

        let adam = Person(name: "Adam", age: 25)

        print("Adam \(adam)")
        let moved = ExPerson()

        // __swift_interopStaticCast(from: Int)

        _ = consume moved

        /*  */var list: List<String> = .init()
        list.push("one")
        list.push("two")

        var listlist: List<List<String>> = .init()
        listlist.push(list)
        // list.push("three")  // now forbidden, list was consumed
        list = listlist.pop()!  // but if we move it back out...
        list.push("three")  // this is allowed again

        list.forEach { element in
            print(element, terminator: ", ")
        }
        // prints "three, two, one, "
        print()
        while let element = list.pop() {
            print(element, terminator: ", ")
        }
        // prints "three, two, one, "
        print()

        

        var nce = NonCopyableEnum.one  // must be var not let else compiler crashes
        switch consume nce {
            case .one: ()
            case .two: ()
            case .three(let y): y.consumingfunc()
        }

        nce = .two

        #if $BorrowingSwitch || hasFeature(BorrowingSwitch)
            let nc = NonCopyEnum.one
            switch /* _borrowing */ nc {
                case .one: ()
                case .two: ()
                case .three(let borrowing y): y.borrowingfunc()
            }
        #endif

        let pType = Person.self

        let metatype: Any.Type = pType

        print(existential(pType))

        print(_openExistential(metatype, do: existential)) // calls existential(T.Type)

        print(existential(metatype)) // calls existential(_: Any.Type)

        #if $ImplicitLastExprResults && hasFeature(ImplicitLastExprResults)
            _ = returnLastExpr()
        #endif

        print(existential(_openExistential(metatype, do: existential)))

        print(existential(metatype)) // Error:

        measure("CXX_ThreadPool_globalPool_Wait_Unret") { _ in
            let group = WaitGroup()
            let grp = Unmanaged.passUnretained(group).toOpaque()
            for _ in 1...1_000 {
                group.enter()
                CXX_ThreadPool.getGlobalPool().submit(grp) { grp in
                    Unmanaged<WaitGroup>.fromOpaque(grp).takeUnretainedValue().done()
                }
            }
            group.waitForAll()
        }

        measure("CXX_ThreadPool_globalPool_Wait_Ret") { _ in
            let group = WaitGroup()
            let grp = Unmanaged.passRetained(group).toOpaque()
            for _ in 1...1_000 {
                group.enter()
                CXX_ThreadPool.getGlobalPool().submit(grp) { grp in
                    Unmanaged<WaitGroup>.fromOpaque(grp).retain().takeRetainedValue().done()
                }
            }
            group.waitForAll()
        }

    }
}
