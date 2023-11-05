#ifndef Header_M
#define Header_M

#include <iostream>
#include <bridging.h>

class SWIFT_NAME(CXX_STRUCT) FibonacciCalculatorCplusplus {
public:
    FibonacciCalculatorCplusplus(bool printInvocation);
    uint fibonacci(uint value) const;
private:
    bool printInvocation;
};

#endif
