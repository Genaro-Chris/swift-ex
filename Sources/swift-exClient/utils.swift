import CXX_Thread
import CustomExecutor
import Foundation
import Interface
// import Observation
import SwiftLib
import SwiftWithCXX
import _Differentiation
import cxxLibrary

@_used var usedVar: Int = 1
@_section("__TEXT,__mysection") var sectionVar: Int = 2

internal final class UniqueThread: Thread {

    var name_: String

    let block: () -> Void

    override var name: String? {
        get {
            name_
        }
        set {
            name_ = newValue ?? ""
        }
    }

    init(name: String, block: @escaping () -> Void) {
        self.name_ = name
        self.block = block
        super.init()
    }

    override func main() {
        print("Main called")
        block()
    }

    override func start() {
        print("Running on custom Thread")
        super.start()
    }
}

dynamic func productss(acb: Int) -> Int {
    print("\(#function) was called")
    return acb * acb
}

@_dynamicReplacement(for:productss(acb:))
func quotient(y: Int) -> Int {
    _ = productss(acb: y)
    print("\(#function) was called")
    return y / y
}

extension SIMD2
where
    Self: Differentiable, Scalar: BinaryFloatingPoint & Differentiable,
    Scalar.TangentVector: BinaryFloatingPoint, TangentVector == Self
{

    @inlinable
    func temporarySum() -> Scalar {
        self.sum()
    }

    @inlinable
    @derivative(of: temporarySum)
    func _vjpTemporarySum() -> (value: Scalar, pullback: (Scalar.TangentVector) -> TangentVector) {
        (temporarySum(), { v in Self(repeating: Scalar(v)) })
    }

}

struct Perceptron: Differentiable {
    var weight: SIMD2<Float> = .random(in: -1 ..< 1)
    var bias: Float = 0

    @differentiable(reverse)
    func callAsFunction(_ input: SIMD2<Float>) -> Float {
        (weight * input).temporarySum() + bias
    }
}

extension Thread {
    var id: String {
        String(getThreadID())
    }
}

/* do {
        typealias OpaqueJob = UnsafeMutableRawPointer
        typealias EnqueueOriginal = @convention(c) (OpaqueJob) -> Void
        typealias EnqueueHook = @convention(c) (OpaqueJob, EnqueueOriginal) -> Void

        let handle = dlopen(nil, RTLD_NOW) //dlopen(nil, 0) // #dsohandle
        let enqueueGlobal_hook_ptr = dlsym(handle, "swift_task_enqueueGlobal_hook")!
            .assumingMemoryBound(to: EnqueueHook.self)

        enqueueGlobal_hook_ptr.pointee = { opaque_job, original in
            //print("simple example succeeded")
            //original(opaque_job)

            // In real implementation, move job to your workloop
            // and eventually run:

            let job = unsafeBitCast(opaque_job, to: UnownedJob.self)
            CustomGlobalExecutor.shared.enqueue(job)
            //job.runSynchronously(on: .generic)
        }
    } */

@_cdecl("swift_task_enqueueMainExecutor")
func _enqueueMain(_ job: OpaquePointer) {
    let job = unsafeBitCast(job, to: UnownedJob.self)
    MyMainActor.shared.enqueue(job)
}

func jo() {
    func memCpy<T>(lhs: UnsafePointer<T>, rhs: UnsafePointer<T>) -> Bool {
        _ = malloc(MemoryLayout<T>.size)
        return memcmp(lhs, rhs, MemoryLayout<T>.size) == 0
    }

    var x = 23
    var y = 43

    print("x: \(x), y: \(y)")

    print("Successful: \(memCpy(lhs: &x, rhs: &y))")

    print("x: \(x), y: \(y)")

}

@_marker
protocol Send {}

#if $TypedThrows
    enum NewError: Error {
        case oops
    }
    func throwing_func() throws(NewError) {
        throw NewError.oops
    }

#endif

struct V<each T> {}

//struct NoncopyableGen<T: _Copyable>: ~Copyable {}

//struct NoncopyableGen<T>: ~Copyable where T: _Copyable {}

extension Int: Send {}

@dynamicCallable
struct NonCopyWithGen<T>: ~Copyable {
    var item: T
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

    public init(_ inner: T) {
        self.inner = inner
    }
}

class UnownedRef {

    unowned let ref: WeakRef

    init(ref: WeakRef) {
        self.ref = ref
    }

}

class WeakRef {

    weak var ref: UnownedRef?
}

/* class Box<each Stored>{
        var stored: (repeat each Stored)
        init(_ boxed: repeat each Stored) {
            stored = (repeat each boxed)
        }
    } */

func forValueType<T: _BitwiseCopyable>(value: T) {
    print("\(value) is of type \(type(of: value))")

}

extension Int: _BitwiseCopyable {}
//extension ThreadPool : _BitwiseCopyable {}

class SingleBox<Boxed> {
    var boxed: Boxed
    init(_ single: Boxed) {
        self.boxed = single
    }

}

struct Angle {
    private var degrees: Double
    private var point: Double = 0
    var radians: Double {
        @storageRestrictions(initializes: degrees)
        init(initialValue) {
            print("init accessor initializes degrees")
            degrees = initialValue * 180 / Double.pi
        }
        get {
            degrees * Double.pi / 180
        }
        set {
            degrees = newValue * 180 / Double.pi
        }
    }

    var points: Double {
        @storageRestrictions(accesses: point)
        init(newValue) {
            print("init accessor accesses point")
            point = newValue
        }
        get {
            point
        }
        set {
            point = newValue
        }
    }

    init() {
        self.degrees = 0
        self.points = 0
        self.radians = 0
    }

    init(degrees: Double, point: Double, radian: Double) {
        self.degrees = degrees
        self.points = point
        self.radians = radians
    }
}

func example<each T>(_ pack: repeat each T, tuple_pack: (repeat each T)) {
    print("pack", (repeat each pack))
    print("tuple_pack", (repeat each tuple_pack))

    print("iterate pack")
    #if hasFeature(PackIteration) || $PackIteration
        for (l, r) in repeat (each pack, each tuple_pack) {
            print(l, r)
        }
    #endif
    //Not yet

    print("pack and tuple_pack", (repeat (each pack, each tuple_pack)))
    print("tuple_pack and pack", (repeat (each tuple_pack, each pack)))
}

class Something {

    struct Header {

        var size = 0
        var isItMonday = false
    }
    private var header = Header()
    private var storage: UnsafeMutableRawPointer {
        _getUnsafePointerToStoredProperties(self) + MemoryLayout<Header>.stride
    }
}

func hasPadding<T>(_ value: T) -> Bool {
    let size = MemoryLayout<T>.size
    let fieldsSize = sizeOfAllFields(value)
    print("size: \(size), fieldsSize: \(fieldsSize)")
    precondition(fieldsSize <= size)
    return size != fieldsSize
}

func sizeOfAllFields(_ value: Any) -> Int {
    let m = Mirror(reflecting: value)
    switch m.displayStyle {
        case .none:
            switch value {
                case is Int8: return 1
                case is Int16: return 2
                case is Int32: return 4
                case is Int64: return 8
                case is Int: return MemoryLayout<Int>.size
                case is UInt8: return 1
                case is UInt16: return 2
                case is UInt32: return 4
                case is UInt64: return 8
                case is UInt: return MemoryLayout<UInt>.size
                case is Float: return MemoryLayout<Float>.size
                case is Double: return MemoryLayout<Double>.size
                default: fatalError("TODO")
            }
        case let .some(wrapped):
            switch wrapped {
                case .struct:
                    return m.children.reduce(0) {
                        $0 + sizeOfAllFields($1.value)
                    }
                case .class:
                    fatalError("TODO")
                case .enum:
                    fatalError("TODO")
                case .tuple:
                    return m.children.reduce(0) {
                        $0 + sizeOfAllFields($1.value)
                    }
                case .optional:
                    // value is Any here
                    let v = value as Any?
                    if let v {
                        return sizeOfAllFields(v)  // WRONG
                    } else {
                        return MemoryLayout.size(ofValue: v)  // WRONG!
                    }
                case .collection:
                    fatalError("TODO")
                case .dictionary:
                    fatalError("TODO")
                case .set:
                    fatalError("TODO")
                @unknown default: 
                    fatalError("TODO")
            }
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
struct CoW<T> {
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

func downcast<T: AnyObject>(_ obj: AnyObject, to type: T.Type) -> T {
    unsafeDowncast(obj, to: type)
}

//

//@Observable
class Ex: CustomStringConvertible {
    var age: UInt = 0
    var name: String = ""

    var description: String {
        "Ex(age: \(age), name: \(name))"
    }

    func callAsFunction() {
        print("Call as function called")
    }

    init(age: UInt, name: String) {
        self.age = age
        self.name = name
    }

    init() {}
}

@CustomCodable
struct PersonDetail: CustomStringConvertible {
    var description: String {
        self.details.description
    }

    @CoW var details: Ex = Ex(age: 18, name: "Ada")
}

#if !os(Linux)
    func confirm() {
        _ = withObservationTracking {
            details.age
        } onChange: {
            DispatchQueue.main.async {
                print("Name changed \(details.name)")
                confirm()
            }
        }
    }

    func observationStream<T>(applying: @escaping () -> T) -> AsyncStream<T> {
        AsyncStream { cont in
            @Sendable func observe() {
                let result = withObservationTracking {
                    applying()
                } onChange: {
                    DispatchQueue.main.async {
                        observe()
                    }
                }
                cont.yield(result)
            }
            observe()
        }
    }

/*  let changes = observationStream {
        details.age
    }

    Task {
        for await age in changes {
            print("Details age \(age)")
        }
    }

    confirm()

    for _ in 0..<5 {
        details.name = "\(Int.random(in:10000...200000))"
    }
     */
#endif

extension DispatchQueue: SerialExecutor, @unchecked Sendable {
    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        self.async {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    static let shared = DispatchQueue(label: "DispatchQueue-Executor")

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: Self.shared)  //Self.global(priority: .low))
    }
}

class OClass {
    var age = 0

    deinit {
        print("Deinitializing \(self)")
    }
}

@globalActor
public actor CustomActor {

    static public let shared = CustomActor()

    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        //DispatchQueue(label: "Ex", attributes: .concurrent).asUnownedSerialExecutor()
        .sharedUnownedExecutor
    }

    func example() async {
        let value: SwiftLib.SwiftProtocol = CXX_STRUCT(false)
        print(value)
        print("Fib 5 \(SwiftWithCXX.CXX_STRUCT(true).fibonacci(5))")
        print(
            "CustomActor instance Thread \(Thread.current.name ?? "main") \(Thread.current.qualityOfService) executed \(Thread.current.isMainThread)\n"
        )
        print("Executing \(Thread.current.description) with id \(Thread.current.id)")
    }

    #if $TransferringArgsAndResults || hasFeature(TransferringArgsAndResults)
        func take(_ value: transferring OClass) {
            print(value)
        }
    #endif

}

actor NewActor {
    //nonisolated public var unownedExecutor: UnownedSerialExecutor { CustomExecutor.sharedDistributedUnownedExecutor }
    nonisolated public var unownedExecutor: UnownedSerialExecutor { .sharedSampleExecutor }
    private var counter_ = 0
    var counter: Int {
        counter_
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
        Thread.sleep(forTimeInterval: 0.18)
        print("Thread ended")
    }
    thread.swap_with {
        print(Thread.current.name as Any)
        print("Help swap")
        Thread.sleep(forTimeInterval: 0.10)
        print("SWAP ENDED")
    }
    thread.yield()
    thread.detach()
    thread.join_all()
    try await c()
}

func extendLife(_ obj: AnyObject) {
    withExtendedLifetime(obj) { _ in }
    _fixLifetime(obj)
}

extension TaskPriority: CaseIterable {
    public static var allCases: [TaskPriority] {
        [.low, .medium, .high, .utility, .userInitiated, .background]
    }
}

func returnLastExpr() -> Float {
    let result = Float.random(in: 0...1000)
    result
}

func dou() {
    do {
        if true {
            throw cxx_impl_exception.init("cxx_exception")
        }
    } catch is cxx_impl_exception {
        print("cxx_impl_exception error")
    } catch {
        print("\(error)")
    }

}

#if hasAttribute(retroactive) || hasFeature(RetroactiveAttribute)

    extension cxx_impl_exception: @retroactive Error, @retroactive @unchecked Sendable {}

#else
    extension cxx_impl_exception: Error, @unchecked Sendable {}
#endif

@_moveOnly
class Moved {
    var name: String = "Moved"
    deinit {
        print("Deinit \(name)")
    }
}

@extractConstantsFromMembers
protocol ConstantsFromMembers {}

struct ConstantStruct: ConstantsFromMembers {
    let foo = "foo"
    let cane: [String] = ["bar", "baz"]
}

struct MoveOnly: ~Copyable {
    var name = " MoveOnly"
    deinit {
        print("Deinit \(name)")
    }
}

func play() {

    @_noImplicitCopy  // same as consume
    let str = ""

    let new_str = copy str  // without copy compiler error

    print(new_str)
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

@_fixed_layout
@usableFromInline
class ExPerson {
    var name = "Adam"
    var age = 0
}

func existential<T>(_: T.Type) -> T.Type { T.self }

func isolatedTo(_: isolated (any Actor)) async {}
