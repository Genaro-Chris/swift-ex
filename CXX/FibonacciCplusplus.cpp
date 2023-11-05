#include <Fibonacci.h>
#include <iostream>
#include <SwiftLib-Swift.h>

FibonacciCalculatorCplusplus::FibonacciCalculatorCplusplus(bool printInvocation) : printInvocation(printInvocation) {}

uint FibonacciCalculatorCplusplus::fibonacci(uint value) const
{

    // SwiftLib::Hello(nullptr);
    //  Print the value if applicable.
    if (printInvocation)
        std::cout << "[c++] fibonacci(" << value << ")\n";

    // Handle the base case of the recursion.
    if (value <= 1)
        return 1;

    // Create the Swift `FibonacciCalculator` structure and invoke its `fibonacci` method.
    auto swiftCalculator = SwiftLib::FibonacciCalculator::init(printInvocation);
    auto ages = swiftCalculator.getAges();
    return swiftCalculator.fibonacci(value - 1) + swiftCalculator.fibonacci(value - 2);
}
