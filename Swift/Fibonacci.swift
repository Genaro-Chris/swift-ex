import SwiftWithCXX

public typealias Signal = @convention(c) () -> Void

public func take(body: @convention(c) () -> Void) {
    body()
}

public struct FibonacciCalculator {

    public let ages = [1, 3, 4, 5, 2, 6]

    private let printInvocation: Bool

    public init(printInvocation: Bool) {
        self.printInvocation = printInvocation
    }

    public func fibonacci(_ value: UInt32) -> UInt32 {
        // Print the value if applicable.
        if printInvocation {
            print("[swift] fibonacci(\(value))")
        }

        // Handle the base case of the recursion.
        guard value > 1 else {
            return 1
        }

        // Create the C++ `FibonacciCalculatorCplusplus` class and invoke its `fibonacci` method.
        let cxxCalculator = CXX_STRUCT.init(
            printInvocation)
        return cxxCalculator.fibonacci(value - 1) + cxxCalculator.fibonacci(value - 2)
    }
}

public protocol SwiftProtocol {}

@_expose(Cxx)
public struct SwiftToCXXStruct {
    @_expose(Cxx)
    public var x = 0
    @_expose(Cxx)
    public mutating func set(x: Int) -> Int {
        let y = self.x
        self.x = x
        return y
    }
}

public func returnSwiftToCXXStruct(x: Int = 0) -> SwiftToCXXStruct {
    return SwiftToCXXStruct(x: x)
}

public actor Hello {
    init() {}
    var helloCount = 5
}

@_extern(c, "cxx_fuck")
public func fuck()

public func DisplayStringAndReturnStrCount(msg: String) -> UInt {
    print(msg)
    return UInt(msg.count)
}
