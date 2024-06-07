#include <swift/bridging>
#include "SwiftLib-Swift.h"
#include <stdlib.h>

class SWIFT_NAME(CXX_STRUCT) FibonacciCalculatorCplusplus {
public:
    FibonacciCalculatorCplusplus(bool printInvocation);
    uint fibonacci(uint value) const;
private:
    bool printInvocation;
} SWIFT_CONFORMS_TO_PROTOCOL(SwiftLib.SwiftProtocol);

extern "C"
void cxx_fuck();
