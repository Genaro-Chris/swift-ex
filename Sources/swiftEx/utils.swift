import CXX_Thread
internal import CustomExecutor
import Foundation
@_exported import Interface
import SwiftLib
import SwiftWithCXX
import _Differentiation
import cxxLibrary

#if canImport(Observation) && os(macOS)
    import Observation
#endif

@_used nonisolated(unsafe) var usedVar: Int = 1
@_section("__TEXT,__mysection") nonisolated(unsafe) var sectionVar: Int = 2

_const let onlyConst: Int = 0

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

dynamic func product(b: Int) -> Int {
    print("\(#function) was called")
    return b * b
}

@_dynamicReplacement(for:product(b:))
func quotient(y: Int) -> Int {
    _ = product(b: y)
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
    var weight: SIMD2<Float> = .random(in: -1..<1)
    var bias: Float = 0

    @differentiable(reverse)
    func callAsFunction(_ input: SIMD2<Float>) -> Float {
        (weight * input).temporarySum() + bias
    }
}

extension Thread {
    var id: String {
        // "\(getThreadID())"
        // <unknown>:0: error: circular reference
        // <unknown>:0: note: through reference here
        // swift 6.0 debug build
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

/*
    warning: extension declares a conformance of imported type 'cxx_impl_exception' to imported protocol 'SwiftProtocol';
    this will not behave correctly if the owners of 'cxxLibrary' introduce this conformance in the future
    // solution
*/
extension cxxLibrary.cxx_impl_exception: SwiftLib.SwiftProtocol {}

func exFunctype() {
    let _:
        @convention(thin) (  //@convention(thick) () -> (),
            @convention(thin) () -> Void,
            @convention(c) () -> Void,
            @convention(c,cType:"intptr_t (*)(size_t)") (Int) -> Int
            //@convention(block) () -> Void,
            //@convention(method) () -> Void,
            //@convention(objc_method) () -> Void,
            //@convention(witness_method:Bendable) (Int) -> () -> Void
        ) -> Void
}

#if $TypedThrows
    enum NewError: Error {
        case oops
    }
    func throwing_func() throws(NewError) {
        throw NewError.oops
    }

#endif

struct V<each T> {}

func useV() {
    let v: V<> = V< >()  // : V<>

    print(v, type(of: v))
}

func useThen() {
    let resultInt: Int = if Bool.random() {
        print("Then statement")
        then 0
    } else {
        print("Then")
        then 1
    }

    print(resultInt)
}

extension Int: Send {}

@dynamicCallable
struct NonCopyWithGen<T>: ~Copyable {
    var item: T
    func dynamicallyCall(withArguments: [T] = []) {
        print("Dynamically called this with \(withArguments)")
    }
}

// Generic struct 'NonCopyWithGen' required to be 'Copyable' but is marked with '~Copyable'
// extension NonCopyWithGen: Copyable where T: Copyable {}

@dynamicCallable
struct CopyWithGen<T>: Copyable {
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

func forValueType<T: BitwiseCopyable>(value: T) {
    print("\(value) is of type \(type(of: value))")

}

extension Int: BitwiseCopyable {}

class SingleBox<Boxed> {
    var boxed: Boxed
    init(_ single: Boxed) {
        self.boxed = single
    }

}

struct Angle {
    @available(
        *, noasync, message: "Example of a declaration that can not be used in an async context"
    )
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

    #if hasFeature(PackIteration) || $PackIteration
        print("iterate pack")
        for (l, r) in repeat (each pack, each tuple_pack) {
            print(l, r)
        }
    #endif

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

func isEqual<T>(a: T, b: T) -> Bool {
    var (a, b) = (a, b)
    if _isPOD(T.self) {
        return withUnsafePointer(to: &a) { aptr -> Bool in
            return withUnsafePointer(to: &b) { bptr -> Bool in
                return memcmp(aptr, bptr, MemoryLayout<T>.size) == 0
            }
        }

    }
    fatalError("Hmm")
}

func isEqual<T: Equatable>(a: T, b: T) -> Bool {
    a == b
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

extension FutexLock {
    func locked<T>(@_implicitSelfCapture _ block: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try block()
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

#if $TypeWrappers && compiler(<5.9)
    @typeWrapper
    struct Wrapper<W, S> {
        var underlying: S
        init(for wrappedType: W.Type, storage: S) {
            underlying = storage
        }
        subscript<V>(propertyKeyPath propertyPath: KeyPath<W, V>, storageKeyPath storagePath: KeyPath<S, V>) -> V {
            underlying[keyPath: storagePath]
        }
        subscript<V>(propertyKeyPath propertyPath: WritableKeyPath<W, V>, storageKeyPath storagePath: WritableKeyPath<S, V>) -> V {
            underlying[keyPath: storagePath]
        }
    }

    @Wrapper
    struct TypeWithLetProperties<T> {
        var val: T?
        init(cond: Bool = true, initialValue: T? = nil) {
            if cond {
                if let initialValue = initialValue {
                    self.val = initialValue
                } else {
                    self.val = nil
                }
            } else {
                self.val = nil
            }
        }
    }
#endif

// https://antonz.org/uuidv7/
extension UUID {
    static func v7() -> Self {
        // random bytes
        var value = (
            UInt8(0),
            UInt8(0),
            UInt8(0),
            UInt8(0),
            UInt8(0),
            UInt8(0),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255),
            UInt8.random(in: 0...255)
        )

        // current timestamp in ms
        let timestamp: Int = .init(Date().timeIntervalSince1970 * 1000)

        // timestamp
        value.0 = .init((timestamp >> 40) & 0xFF)
        value.1 = .init((timestamp >> 32) & 0xFF)
        value.2 = .init((timestamp >> 24) & 0xFF)
        value.3 = .init((timestamp >> 16) & 0xFF)
        value.4 = .init((timestamp >> 8) & 0xFF)
        value.5 = .init(timestamp & 0xFF)

        // version and variant
        value.6 = (value.6 & 0x0F) | 0x70
        value.8 = (value.8 & 0x3F) | 0x80

        return UUID(uuid: value)
    }
}

typealias NonCopyableTuplePair<T: ~Copyable, V: ~Copyable> = (T, V)

/* extension Int {
    public var value: Int { self }
} */

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

// @Observable
class Ex: CustomStringConvertible, @unchecked Sendable {
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

@available(macOS 13.0, *)

public struct BackDeployable {}

extension BackDeployable {
    @backDeployed(before: macOS 12.0)
    public func deployed() {}
}

@CustomCodable
struct PersonDetail: CustomStringConvertible {
    var description: String {
        self.details.description
    }

    @CoW var details: Ex = Ex(age: 18, name: "Ada")
}


extension DispatchQueue: @retroactive SerialExecutor, @unchecked @retroactive Sendable {
    public func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        self.async {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    // static let shared = DispatchQueue(label: "DispatchQueue-Executor")

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)  //Self.global(priority: .low))
    }
}

func playWith() {
    var list: List<String> = .init()
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
}

func playWithCopy() {
    // compiler bug 
    // swift 6
    var list1: ListCopy<MoveOnlyStruct<String>> = .init()
    list1.push(.init("one_copy"))
    list1.push(.init("two_copy"))

    var listlist1: ListCopy<ListCopy<MoveOnlyStruct<String>>> = .init()
    listlist1.push(list1)
    // list.push("three_copy")  // now forbidden, list was consumed
    list1 = listlist1.pop()!  // but if we move it back out...
    list1.push(.init("three_copy"))  // this is allowed again

    list1.forEach { element in
        print(element.description, terminator: ", ")
    }
        // prints "three_copy, two_copy, one_copy, "
    print()
    while let element = list1.pop() {
        print(element.description, terminator: ", ")
    }
    // prints "three, two, one, "
    print()

}

class OClass {
    var age = 0

    func method() {}

    deinit {
        print("Deinitializing \(self)")
    }
}

@globalActor
public actor CustomActor {

    static public let shared = CustomActor()

    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        //DispatchQueue(label: "Ex", attributes: .concurrent).asUnownedSerialExecutor()
        MainExecutor.sharedUnownedExecutor
    }

    func example() async {
        let value: SwiftProtocol = CXX_STRUCT(false)
        print(value)
        print("Fib 5 \(CXX_STRUCT(true).fibonacci(5))")
        print(
            "CustomActor instance Thread \(Thread.current.name ?? "main") \(Thread.current.qualityOfService) executed \(Thread.current.isMainThread)\n"
        )
        print("Executing \(Thread.current.description) with id \(Thread.current.id)")  //
    }

    #if $TransferringArgsAndResults || hasFeature(TransferringArgsAndResults)
        func take(_ value: transferring OClass) {
            print(value)
        }

        func retNs() async -> transferring OClass {
            return OClass()
        }
    #endif

    /* func run<T>(_ block: () throws -> T) rethrows -> T {
        block()
    }

    private static func runWith<Act: Actor, T>(act: isolated Act, _ block: () throws -> T) rethrows -> T {
        return try block()
    }

    static func run<T: Sendable>(_ block: () throws -> T) async rethrows -> T {
        return try await runWith(act: shared) {
            try block()
        }
    } */

    private static func runOn<Act: Actor, T: Sendable>(
        act: isolated Act = CustomActor.shared, _ block: () throws -> T
    ) async rethrows
        -> T
    {
        return try block()
    }

    private static func runWith<Act: Actor, T: Sendable>(
        act: isolated Act = #isolation ?? CustomActor.shared, _ block: @isolated(any) () throws -> T
    ) async rethrows
        -> T
    {
        return try await block()
    }

    static func run<T: Sendable>(_ block: @escaping @CustomActor () throws -> T) async rethrows -> T {
        /* _ = extractIsolation { () throws -> T in
            return try await block()
        } */
        return try await runWith(act: shared, block)
    }

}

actor NewActor {
    //nonisolated public var unownedExecutor: UnownedSerialExecutor { CustomExecutor.sharedDistributedUnownedExecutor }
    // nonisolated public var unownedExecutor: UnownedSerialExecutor { .sharedSampleExecutor }
    let queue = DispatchQueue(label: "NewActor")
    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }
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
nonisolated func closure(_ c: () async throws -> Void) async rethrows {
    let thread = CXX_Thread.create {
        print(Thread.current.name as Any)
        print("Help")
        print("Thread ended")
    }
    thread.swap_with {
        print(Thread.current.name as Any)
        print("Help swap")
        print("SWAP ENDED")
    }
    thread.yield()
    thread.detach()
    thread.join_all()
    try await c()
}

// compiler bug swift 6.0 to use AnyObject as argument type
func extendLife<T: AnyObject>(_ obj: T) { 
    withExtendedLifetime(obj) { _ in }
    _fixLifetime(obj)   
}

extension TaskPriority: @retroactive CaseIterable {
    public static var allCases: [TaskPriority] {
        [.low, .medium, .high, .utility, .userInitiated, .background]
    }
}

#if $ImplicitOpenExistenials || hasFeature(ImplicitOpenExistenials)
    func takeError<E: Error>(_ error: E) {}

    func passError(_ err: any Error) {
        takeError(err)
    }
#endif

#if $ImplicitLastExprResults || hasFeature(ImplicitLastExprResults)
    func returnLastExpr() -> Float {
        let result = Float.random(in: 0 ... 1000)
        print("ImplicitLastExprResults: \(result)")
        result
    }
#endif

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

@_lexicalLifetimes
func lexy(_ c: String) {
    print("@_lexicalLifetimes func with \(c)")
}

func noInout<S>(@_nonEphemeral at pointer: UnsafeMutablePointer<S>) {
    let sValue: S = pointer.move()
    print("Got \(sValue) for @_nonEphemeral pointer")
}

@_originallyDefinedIn(module:"foo", OSX 13.13)
@_optimize(none)
public func foo1() {}

@_specialize(where T: _BridgeObject)
func foo<T>(_ t: T) {}

// public typealias Body = @_opaqueReturnTypeOf("Send", 0) __

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

@sensitive
struct SensitiveStruct {

    var a: UInt32 = 0xdeadbeaf
    var b: UInt32 = 0xdeadbeaf
    var c: UInt32 = 0xdeadbeaf
}

@_eagerMove
struct EagerlyMove {}

@_noEagerMove
struct NotEagerlyMove {}

@extractConstantsFromMembers
protocol ConstantsFromMembers {}

@Sendable func sendableFunc(_: Sendable...) {
    print("Sendable variadic argument")
}

struct ConstantStruct: ConstantsFromMembers {
    let foo: String = "foo"
    let cane: [String] = ["bar", "baz"]
}

@available(OpenBSD, unavailable, message: "malloc_size is unavailable.")
@available(Windows, unavailable)
//@available(Linux, unavailable)
struct UnavailBSDWin {}

struct MoveOnly: ~Copyable {
    var name: String = "MoveOnly"
    deinit {
        print("Deinit \(name)")
    }
}

func play() {

    @_noImplicitCopy  // same as consume
    let str: String = ""

    let new_str: String = copy str  // without copy compiler error

    print(new_str)
    let moveInstance: Moved = Moved()
    let anotherInstance: MoveOnly = MoveOnly()

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
    var name: String = "Adam"
    var age: Int = 0
}

func takeOnlyConst(_: _const Int) {}

@_preInverseGenerics
func existential<T>(_: T.Type) -> T.Type { T.self }

func existential(_ v: Any.Type) -> Any.Type { v }

struct AnyTp: Tp {
    init<T: Tp>(erasing: T) {}
}

@_typeEraser(AnyTp)
protocol Tp {}

protocol P {}

struct ConcreteP: P, Hashable {
    init() {}
}

func typeErased() -> some P { ConcreteP() }

protocol Moving: ~Copyable {
    init(_ value: Int32)
    var value: Int32 { get }
}

struct Mover: ~Copyable {
    let value: Int32
}

extension NonCopyableType: Moving {}

extension Mover: Moving {
    init(_ value: Int32) {
        self.value = value
    }
}

func play_withMove() {
    var mv_: Mover = Mover(value: 32)

    var move_: NonCopyableType = NonCopyableType(32)

    // _ = move_ // consume here

    // _ = mv_ // consume here

    func NC<T: Moving & ~Copyable>(mv: borrowing T) {
        print(mv.value)
        //Task { dump(mv.value) }
    }

    func consumer<T: ~Copyable>(_ val: consuming T) {
        _ = consume val
    }

    func inoutConsume<T: Moving & ~Copyable>(_ val: inout T) {
        _ = consume val //consumed twice
        val = .init(.random(in: 0...100))
    }

    NC(mv: move_)
    NC(mv: mv_)

    inoutConsume(&move_)
    inoutConsume(&mv_)

    consumer(move_)
    consumer(mv_)

    //_ = consume move_
    //_ = consume mv_
}

fileprivate func o(mv: borrowing MoveOnlyType) {}

func cxx_move() {
    do {
        let moveOnly: MoveOnlyType = MoveOnlyType(9)
        o(mv: moveOnly)
        let new: MoveOnlyType = moveOnly
        print(new.value)
        new.borrow_this()
        new.consume_this()
    }
}