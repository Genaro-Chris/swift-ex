#ifndef Header_M
#define Header_M

#include <swift/bridging>
#include <sys/types.h>
//#include "SwiftLib-Swift.h"

class SWIFT_NAME(CXX_STRUCT) FibonacciCalculatorCplusplus {
public:
    FibonacciCalculatorCplusplus(bool printInvocation);
    uint fibonacci(uint value) const;
private:
    bool printInvocation;
} SWIFT_CONFORMS_TO_PROTOCOL(SwiftLib.SwiftProtocol);

void cxx_fuck();

#endif
