import CXX_Thread
import CustomExecutor
import Foundation
import Interface
import SwiftWithCXX
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
        original(opaque_job)

        // In real implementation, move job to your workloop
        // and eventually run:

        //let job = unsafeBitCast(opaque_job, to: UnownedJob.self)
        //CustomGlobalExecutor.shared.enqueue(job)
        //job.runSynchronously(on: .generic)
    }
}

Task.detached {
    //exit(0)
    print("Example task detached")
}

try await Task.sleep(for: .seconds(2))

//dispatchMain()


print("Multithreaded \(Thread.isMultiThreaded())")
@_marker
protocol Send {}

#if hasFeature(GenerateBindingsForThrowingFunctionsInCXX)
    print("GenerateBindingsForThrowingFunctionsInCXX exists in this compiler")
#endif

#if $TypedThrows
    enum NewError: Error {
        case oops
    }
    func throwing_func() throws { //(NewError) -> Void {
        throw NewError.Oops
    }
    print("Typed Throws")

    do {
        try throwing_func()
    } catch {
        print("Caught \(error)")
    }
#endif

do {
    let pool = ThreadPool.create(CPU_Count)
    for _ in 1...20 {
        pool.submit {
            print("ThreadPool \(Thread.current.name ?? "Unknown") with id \(Thread.current.id) and description \(Thread.current.description)")
        }
    }
    Thread.sleep(forTimeInterval: 4)
}



struct V<each T> {}

let v = V< >()

//struct NoncopyableGen<T: _Copyable>: ~Copyable {}

//struct NoncopyableGen<T>: ~Copyable where T: _Copyable {}

extension Int: Send {}

@dynamicCallable
struct NonCopyWithGen<T> : ~Copyable {
    var item : T
    func dynamicallyCall(withArguments: [T] = []) {
        print("Dynamically called this with \(withArguments)")
    }
}

@dynamicMemberLookup
struct Accessor<T> {
    private var inner: T
    subscript<V>(dynamicMember value: KeyPath<T, V>) -> V {
        inner[keyPath: value]
    }

    public init( _ inner: T) {
        self.inner = inner
    }
}

/* class Box<each Stored>{
    var stored: (repeat each Stored)
    init(_ boxed: repeat each Stored) {
        stored = (repeat each boxed)
    }
} */


class SingleBox<Boxed> {
    var boxed: Boxed
    init(_ single: Boxed) {
        self.boxed = single
    }

}

/* @propertyWrapper
//@dynamicMemberLookup
struct CopyOnWrite<each Value> {
    var box: Box<repeat each Value>

    var wrappedValue: (repeat each Value) {
        get { box.stored }
        set {
            if (!isKnownUniquelyReferenced(&box)) {
                box = Box(repeat each newValue)
            } else {
                box.stored = (repeat each newValue)
            }
        }
    }

    init(wrappedValue: (repeat each Value)){
        box = Box(repeat each wrappedValue)
    }

    /* subscript<V>(dynamicMember member: repeat WritableKeyPath<each Value, V>) -> V {
        get {
            repeat(self.wrappedValue[keyPath:  (each member)])
        }
        set {
            repeat self.wrappedValue[keyPath: (each member)] = (repeat each newValue)
        }
    } */
    /* var single.box: SingleBox<Value>

    init(wrappedValue: Value) {
        self.single.box = SingleBox(single: wrappedValue)
    }

    var wrappedValue: Value {
        get {
            single.box.boxed
        }
        set {
            if isKnownUniquelyReferenced(&single.box) {
                print("Not unique")
                single.box.boxed = newValue
            } else {
                print("Unique")
                single.box = SingleBox(single: newValue)
            }
        }
    }

    subscript<T>(dynamicMember member: WritableKeyPath<Value, T>) -> T {
        get {
            print("Get")
            return self.wrappedValue[keyPath: member]
        }
        set {
            print("Set")
            self.wrappedValue[keyPath: member] = newValue
        }
        _modify {
            print("Modify")
            yield &self.wrappedValue[keyPath: member]
        }
    } */
} */

//@typeWrapper
@propertyWrapper
@dynamicMemberLookup
struct CoW<T>{
    fileprivate var box: SingleBox<T>
    var wrappedValue: T {
        get {
            return box.boxed
        }
        set {
            if isKnownUniquelyReferenced(&box) {
                self.box.boxed = newValue
            } else {
                self.box = SingleBox(newValue)
            }
        }
    }

    init(wrappedValue: T) {
        self.box = SingleBox(wrappedValue)
    }

    subscript<V>(dynamicMember member: WritableKeyPath<T, V>) -> V {
        get {
            self.wrappedValue[keyPath: member]
        }
        set {
            self.wrappedValue[keyPath: member] = newValue
        }
    }

    var projectedValue: Accessor<T> {
        get {
            Accessor(box.boxed)
        }
        nonmutating set {
            print(newValue)
        }
    }

}

struct Ex: CustomStringConvertible {
    var age: UInt = 0
    var name: String = ""

    var description: String {
        "Ex(age: \(age), name: \(name))"
    }
}

@CustomCodable
struct PersonDetail: CustomStringConvertible {
    var description: String {
        self.details.description
    }

    @CoW var details: Ex = Ex(age: 18, name: "Ada")
}


var person: PersonDetail? = PersonDetail(details: Ex(age: 18, name: "Adam"))
person?.details.name = "Changed"
var person1 = person
var person2 = person

print("Person \(person!)")

print("Person1 \(person1!)")

print("Person2 \(person2!)")


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


let ex:  NonCopyWithGen<UInt> = NonCopyWithGen(item: 23)
ex(1,2,3)

extension DispatchQueue: SerialExecutor, @unchecked Sendable {
    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        self.async {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    static let shared = DispatchQueue(label: "DispatchQueue-Executor")

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: Self.shared) //Self.global(priority: .low))
    }
}

@globalActor
public actor CustomActor {

    static public let shared = CustomActor()

    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        //DispatchQueue(label: "Ex", attributes: .concurrent).asUnownedSerialExecutor()
        CustomExecutor.sharedUnownedExecutor
    }

    func example() async {
        print("Fib 5 \(SwiftWithCXX.CXX_STRUCT(true).fibonacci(5))")
        print(
            "CustomActor instance Thread \(Thread.current.name ?? "main") \(Thread.current.qualityOfService) executed \(Thread.current.isMainThread)\n")
            print("Executing \(Thread.current.description) with id \(Thread.current.id)")
    }
}

actor NewActor {
    nonisolated public var unownedExecutor: UnownedSerialExecutor  { CustomExecutor.sharedDistributedUnownedExecutor }
    private var counter_ = 0
    var counter: Int {
        get {
            counter_
        }
    }
    func append(value: Int) {
        counter_ += value
    }
}


extension NonCopyWithGen where T == Int {}

@throwsToResult("throwing")
@Sendable
func closure(_ c: () async throws -> Void) async rethrows {
    let thread = CXX_Thread.create {
        print(Thread.current.name as Any)
        print("Help")
        Thread.sleep(forTimeInterval: 3)
        print("Thread ended")
    }
    thread.swap_with {
        print(Thread.current.name as Any)
        print("Help swap")
        Thread.sleep(forTimeInterval: 3)
        print("SWAP ENDED")
    }
    thread.yield()
    thread.detach()
    thread.join_all()
    try await c()
}

extension TaskPriority: CaseIterable {
    public static var allCases: [TaskPriority] {
        [.low, .medium, .high, .utility, .userInitiated, .background]
    }
}

let new = NewActor()
await withDiscardingTaskGroup {group in
    let actor = CustomActor()
    for priority in TaskPriority.allCases {
        group.addTask(priority: priority) { 
            Task { @CustomActor in
                print("Task with Custom Actor context")
                await new.append(value: 1)
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

#if hasAttribute(retroactive) || hasFeature(RetroactiveAttribute)

    extension cxx_impl_exception : @retroactive Error, @retroactive @unchecked Sendable {  }
    /* if !Bool.random() {
        throw  cxx_impl_exception.init("cxx_exception")
    } */
#else
    extension cxx_impl_exception: Error, @unchecked Sendable {}
#endif

print("Random number is: ", createUniformPseudoRandomNumberGenerator(1.0, 90.5))

print("Hello World from Swift")

hello_world("Hello world from C++")

var user = ConceptUser("Concept Impl")

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

@_moveOnly
class Moved {
    var name: String = "Moved"
    deinit {
        print("Deinit \(name)")
    }
}

struct MoveOnly: ~Copyable {
    var name = " MoveOnly"
    deinit {
        print("Deinit \(name)")
    }
}

func play() {


    @_noImplicitCopy // same as consume
    let str = ""

    //let new_str = str

    print(str)
    let moveInstance = Moved()
    let anotherInstance = MoveOnly()

    borrower(moveInstance)
    borrower(anotherInstance)
    sharing(moveInstance)

    // owned(moveInstance) use after being consumed
    consumer(moveInstance)
    consumer(anotherInstance)

    print("Done")
    //borrower(moveInstance)

    /* print("First Usage \(moveInstance.name)")

    let another = moveInstance

    print("First usage \(another.name)")

    print("Second Usage \(moveInstance.name)")

    print("Second usage \(another.name)") */

}

//play()

func borrower(_ instance: borrowing Moved) {
    print("Printing borrowed \(instance.name)")
}

func consumer(_ instance: consuming Moved) {
    print("Printing consumed \(instance.name)")
}

func borrower(_ instance: borrowing MoveOnly) {
    print("Printing borrowed \(instance.name)")
}

func consumer(_ instance: consuming MoveOnly) {
    print("Printing consumed \(instance.name)")
}

func sharing(_ instance: __shared Moved) {
     print("Printing shared \(instance.name)")
}

func owned(_ instance: __owned Moved) {
     print("Printing owned \(instance.name)")
}

@CustomActor
struct Person {
    var name: String
    var age: UInt
}

class ExPerson {
    var name = "Adam"
    var age = 0
}

let adam = Person(name: "Adam", age: 25)

print("Adam \(adam)")
let moved = ExPerson()
