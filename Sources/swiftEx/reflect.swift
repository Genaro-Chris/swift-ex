import Algorithms
import AtomicsShims
import Builtin
import Foundation
import Synchronization

func sync() {
    // Builtin.createTask()
    _ = Synchronization.Atomic.init(56).exchange(43, ordering: .sequentiallyConsistent)
    //var cAtom = AtomicsShims.AtomicInt() // not visible due to cxx interoperable
    //store(&cAtom, 34)
    // _ = [1, 2, 3].evenlyChunked(in: 4) Algorithm Package into directly or indirectly imported
}

/*
swift: swiftc  -O -emit-assembly -module-name output test.swift | swift demangle
swiftc  -O -emit-sil -module-name output test.swift | swift demangle
-Xfrontend -enable-ossa-modules
*/

struct Quantity {
    let quantity: Int
    let unit: Unit?

    enum Error: Swift.Error {
        case a
    }
    var property: Bool {
        get throws(Error) {
            if Bool.random() { .init() } else { throw Error.a }
        }
    }

    init(_ quantity: Int, unit: Unit? = nil) {
        self.quantity = quantity
        self.unit = unit
    }
}

enum Unit: Equatable {
    case liter
    case kilogram
    case meter
}

// extension Quantity: Equatable {}

extension Quantity {
    var destructuredTuple: (quantity: Int, unit: Unit?) { (quantity, unit) }
}

protocol Destructurable {
    func destructured<each Property>(_ key: repeat (KeyPath<Self, each Property>)) -> (
        repeat each Property
    )

    func apply<each Transformed, Error: Swift.Error>(
        _ transform: repeat (Self) throws(Error) -> each Transformed
    ) throws(Error) -> (repeat each Transformed)  // 'rethrows' cannot be combined with a specific thrown error type
}

extension Destructurable {
    func destructured<each Property>(_ key: repeat (KeyPath<Self, each Property>)) -> (
        repeat each Property
    ) {
        return (repeat self[keyPath: each key])
    }

    func apply<each Transformed, Error: Swift.Error>(
        _ transform: repeat (Self) throws(Error) -> each Transformed
    ) throws(Error) -> (repeat each Transformed) {
        try (repeat (each transform)(self))
    }
}

extension Quantity: Destructurable {}

func destructuredQuantityTuple() {
    let quantity = Quantity(12, unit: .liter)
    switch quantity.destructuredTuple {
    case (_, nil):
        ()
    default:
        ()
    }
}

func destructuredQuantity() {
    let quantity = Quantity(39, unit: .meter)
    switch quantity.destructured(\.quantity, \.unit) {

    case (_, nil): ()

    default: ()

    }
}

func destructuredApply() {
    let quantity = Quantity(54, unit: .kilogram)
    do {
        let _: (Int, Unit?, Bool) = try quantity.apply(
            { $0.quantity },
            { $0.unit },
            { try $0.property }
        )
    } catch is Quantity.Error {
        print(Quantity.Error.a)
    } catch {
        print(type(of: error))
    }

}

func ~= (pattern: (Int, Unit), value: Quantity) -> Bool {
    return pattern.0 == value.quantity && pattern.1 == value.unit
}

func destructuredSwitch() {
    let quantity = Quantity(16, unit: .kilogram)
    switch quantity {
    case let val where val.unit == .liter: print("Switch quantity \(val.unit!)")
    case let val where val.unit == .meter: print("Switch quantity \(val.unit!)")
    case let val where val.unit == .kilogram: print("Switch quantity \(val.unit!)")
    default: break

    }
    /* switch quantity {
    case (0, .liter): break
    default: break

    } */
}
