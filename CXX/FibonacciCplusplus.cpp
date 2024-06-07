#include <Fibonacci.h>
#include <iostream>

using namespace SwiftLib;

FibonacciCalculatorCplusplus::FibonacciCalculatorCplusplus(bool printInvocation) : printInvocation(printInvocation) {}

uint FibonacciCalculatorCplusplus::fibonacci(uint value) const
{

    // SwiftLib::Hello(nullptr);
    //  Print the value if applicable.

    swift::String test = "swift::String test";

    auto x = returnSwiftToCXXStruct(34);

    if (printInvocation)
        std::cout << "[c++] fibonacci(" << value << ")\n";

    // Handle the base case of the recursion.
    if (value <= 1)
        return 1;

    // Create the Swift `FibonacciCalculator` structure and invoke its `fibonacci` method.
    auto swiftCalculator = FibonacciCalculator::init(printInvocation);
    auto ages = swiftCalculator.getAges();
    return swiftCalculator.fibonacci(value - 1) + swiftCalculator.fibonacci(value - 2);
}

void cxx_fuck()
{
    std::cout << "cxx_fuck\n";
}