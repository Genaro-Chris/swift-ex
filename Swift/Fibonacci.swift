import CXX_Thread
import SwiftWithCXX
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the Swift API.
*/
import cxxLibrary

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
public actor Hello {}

@_extern(c, "cxx_fuck")
public func fuck()

public func DisplayStringAndReturnStrCount(msg: String) -> UInt {
    print(msg)
    return UInt(msg.count)
}
