import Foundation
import Builtin

class BaseClass {
    init(_ x: Any) {}
    convenience init(conv: Int) {
        self.init(conv)
    }
}

@_inheritsConvenienceInitializers
class SubClass: BaseClass {}

extension BaseClass {

    var subClass: SubClass { SubClass("") }
}

enum NonCopyEnum: ~Copyable {
    case one, two, three(NonStruct)
}

@_staticExclusiveOnly
struct NonCopyableExclusive: ~Copyable {
    var age: Int = 0
    init() {}
}

struct NonCopyable: ~Copyable {
    var age: Int = 0
    init() {}
}

// @_nonEscapable // unknown attribute
struct NonEscapableType: Escapable {
    var age: Int = 0
    // Error in swift 6.0 
    // @_unsafeNonEscapableResult
    init() {}
}

final class SubscriptClass {

    subscript() -> String {
        ""
    }

    static subscript() -> Int {
        0
    }

    class subscript() -> Float {
        9.232
    }
}


@_nonSendable(_assumed) enum NonSendableEnum: @unchecked Sendable {}
@_nonSendable enum NonSendableEnum1: @unchecked Sendable {}

struct NonStruct: ~Copyable {
    borrowing func borrowingfunc() {}
    consuming func consumingfunc() {}
}

enum NonCopyableEnum: ~Copyable {
    case one, two
    case three(NonStruct)
}


func returnNE() -> NonEscapableType {
    return NonEscapableType()
}

#if hasFeature(NonescapableTypes)

func consume_indirect<NE: ~Escapable>(ne: consuming NE) -> /* _consume(ne) */ NE {
    return ne
}



func borrow_indirect<NE: ~Escapable>(ne: borrowing NE) -> /* _borrow(ne) */ NE {
    _ = ne
    return NonEscapableType() as! NE
}

#elseif swift(<6) || compiler(<6) 

    // @_unsafeNonEscapableResult
    func consume_indirect(ne: consuming NonEscapableType) -> NonEscapableType {
        return ne
    }

    // @_unsafeNonEscapableResult
    func borrow_indirect(ne: borrowing NonEscapableType) -> NonEscapableType {
        _ = ne
        return NonEscapableType()
    }

#endif

struct Box<Wrapped: ~Copyable>: ~Copyable {
    private let pointer: UnsafeMutablePointer<Wrapped>
    
    init(_ wrapped: consuming Wrapped) {
        pointer = .allocate(capacity: 1)
        pointer.initialize(to: wrapped)
    }
    
    deinit {
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
    
    consuming func move() -> Wrapped {
        let wrapped = pointer.move()
        pointer.deallocate()
        discard self
        return wrapped
    }
    
    func with(_ body: (borrowing Wrapped)->Void) {
        body(pointer.pointee)
    }
}



extension Box {
    var wrapped: Wrapped { pointer.pointee }
}

struct List<Element: ~Copyable>: ~Copyable {
    struct Node: ~Copyable {
      var element: Element
      var next: Link
    }
    typealias Link = Box<Node>?
  
    var head: Link = nil
}


extension List.Node where Element: ~Copyable {
    func forEach(_ body: (borrowing Element)->Void) {
        body(element)
        next?.with { node in
            node.forEach(body)
        }
    }
}

extension List where Element: ~Copyable {
    mutating func push(_ element: consuming Element) {
        self = List(head: Box(
                Node(element: element, next: self.head)))
    }
    
    mutating func pop() -> Element? {
        switch head?.move() {
        case nil:
            self = .init()
            return nil
        case let node?:
            self = List(head: node.next)
            return node.element
        }
    }
}

extension List where Element: ~Copyable {
    func forEach(_ body: (borrowing Element)->Void) {
        head?.with { node in node.forEach(body) }
    }
}

class MethodModifiers {
    _resultDependsOnSelf func _resultDependsOnSelf() -> Builtin.NativeObject {
        return Builtin.unsafeCastToNativeObject(self)
        }
}

// property accessors 
// unsafeAddress, unsafeMutableAddress, _read, _modify
extension UnsafeMutablePointer {
    @inlinable
    public subscript(i: Int = 0) -> Pointee {
        @_transparent
        unsafeAddress {
            return UnsafePointer(self + i)
        }
        @_transparent
        nonmutating unsafeMutableAddress {
            return self + i
        }
    }

    var value: Pointee {
        _read { yield pointee }
        _modify { yield &pointee }
    }
}

func measure(_ name: String, _ work: (String) throws -> Void) rethrows {
    let timeSpent = try ContinuousClock().measure {
        try work(name)
    }
    print("Time spent on \(name): \(timeSpent)")
}

// Conditional Conformance to Copyability for ~Copyable
struct BoxCopy<Wrapped: ~Copyable>: ~Copyable {

    final class Pointer<Element: ~Copyable> {
        fileprivate var pointer: UnsafeMutablePointer<Element>

        init(_ element: consuming Element) {
            pointer = .allocate(capacity: 1)
            pointer.initialize(to: element)
        }

        func interact<T: ~Copyable>(with: (borrowing Element) throws -> T) rethrows -> T {
            try with(self.pointer.pointee)
        }

        func consume() -> Element {
            let value = pointer.move()
            pointer.deallocate()
            value
        }

    }

    private let pointer: Pointer<Wrapped>

    init(_ wrapped: consuming Wrapped) {
        pointer = .init(wrapped)
    }

    consuming func move() -> Wrapped {
        let value = pointer.consume()
        _ = consume self
        value
    }

    func with(_ body: (borrowing Wrapped) -> Void) {
        pointer.interact(with: body)
    }
}

extension BoxCopy {
    var wrapped: Wrapped { pointer.interact { $0 } }
}

struct ListCopy<Element: ~Copyable>: ~Copyable {
    struct Node: ~Copyable {
        var element: Element
        var next: Link
    }
    typealias Link = BoxCopy<Node>?

    var head: Link = nil
}

extension ListCopy.Node where Element: ~Copyable {
    func forEach(_ body: (borrowing Element) -> Void) {
        body(element)
        next?.with { node in
            node.forEach(body)
        }
    }
}

extension ListCopy where Element: ~Copyable {
    mutating func push(_ element: consuming Element) {
        self = ListCopy(
            head: BoxCopy(
                Node(element: element, next: self.head)))
    }

    mutating func pop() -> Element? {
        switch head?.move() {
        case nil:
            self = .init()
            return nil
        case let node?:
            self = ListCopy(head: node.next)
            return node.element
        }
    }
}

extension ListCopy where Element: ~Copyable {
    func forEach(_ body: (borrowing Element) -> Void) {
        head?.with { node in node.forEach(body) }
    }
}

extension ListCopy.Node {
    func forEach(_ body: (Element) -> Void) {
        body(element)
        next?.with { node in
            node.forEach(body)
        }
    }
}

extension ListCopy {
    mutating func push(_ element: Element) {
        self = ListCopy(
            head: BoxCopy(
                Node(element: element, next: self.head)))
    }

    mutating func pop() -> Element? {
        switch head?.move() {
        case nil:
            self = .init()
            return nil
        case let node?:
            self = ListCopy(head: node.next)
            return node.element
        }
    }
}

extension ListCopy {
    func forEach(_ body: (Element) -> Void) {
        head?.with { node in node.forEach(body) }
    }
}

extension BoxCopy: Copyable {}

extension ListCopy: Copyable {}

extension ListCopy.Node: Copyable {}


struct MoveOnlyStruct<T: CustomStringConvertible>: ~Copyable {

    let value: T

    init(_ value: T) {
        self.value = value
        print("MoveOnlyStruct \(value) Initialized")
    }

    deinit {
        print("MoveOnlyStruct \(value) deinitialized")
    }
}


extension MoveOnlyStruct {
    var description: String { value.description }
}