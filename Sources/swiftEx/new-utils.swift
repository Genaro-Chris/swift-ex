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

#if hasFeature(BodyMacros) || $BodyMacros || hasFeature(PreambleMacros)
    // <unknown>:0: error: circular reference
    // <unknown>:0: note: through reference here
    // swift 6.0
    @Remote
    func f(a: Int, b: String) async throws -> String {
        print("\(a), \(b)")
        return b
    }

    @Traced
    // <unknown>:0: error: circular reference
    // <unknown>:0: note: through reference here
    // swift 6.0
    func aboutToTrace() {
        print(#function)
    }
#endif

@MyOptionSet<UInt8>
struct ShippingOptions {
  private enum Options: Int {
    case nextDay
    case secondDay
    case priority
    case standard
  }
}

#if hasFeature(CodeItemMacros)
    func codeItem(a: Int?, b: Int?) {
        #unwrap
    }

#endif

@DTO
public struct DTOStruct {
    private struct Blueprint {
        var id: UUID
        var createdAt: Date
        var title: String
        var description: String
        var items: [Int]
    }
}

#if canImport(Observation) && os(macOS)

    let details: Ex = Ex(age: 18, name: "Ada")

    func confirm() {
        _ = withObservationTracking {
            details.age
        } onChange: {
            DispatchQueue.main.async {
                print("Name changed \(details.name)")
                confirm()
            }
        }
    }

    func observationStream<T>(applying: @escaping () -> T) -> AsyncStream<T> {
        let clos: UnsafeClosure<T> = UnsafeClosure(body: applying)
        AsyncStream { cont in
            @Sendable func observe() {
                let result = withObservationTracking {
                    clos.body()
                } onChange: {
                    DispatchQueue.main.async {
                        observe()
                    }
                }
                cont.yield(result)
            }
            observe()
        }
    }

    let changes = observationStream {
        details.age
    }

/* Task {
        for await age in changes {
            print("Details age \(age)")
        }
    }

    confirm()

    for _ in 0..<5 {
        details.name = "\(Int.random(in: 10000...200000))"
    } */

#endif

/* typealias ElementType = Int32
typealias ArrayType = [ElementType]

let element: ElementType = 0x1122_3344
let headerSize = 32

func isStackMemory(_ ptr: UnsafeRawPointer) -> Bool {
    let stackBase = pthread_get_stackaddr_np(pthread_self())
    let stackSize = pthread_get_stacksize_np(pthread_self())
    return ptr <= stackBase && ptr >= stackBase - stackSize
}

enum MemoryType: String {

    case stack = "on stack"
    case heap = "on heap"
    case other = "other memory (global?)"

    init(_ ptr: UnsafeRawPointer) {
        if isStackMemory(ptr) {
            self = .stack
        } else {
            self = .other
        }
    }
}

func dumpHex(_ title: String, _ ptr: UnsafeRawPointer, _ size: Int, _ headerSize: Int = 0) {
    var size = size
    var ptr = ptr
    let mallocSize = malloc_size(ptr - headerSize)
    if mallocSize != 0 {
        let mallocBlock = ptr - headerSize
        print(
            "\(title), \(mallocBlock) + \(headerSize) = \(ptr) (\(MemoryType.heap.rawValue)), size: \(headerSize) + \(mallocSize - headerSize) = \(mallocSize) -> "
        )
        size = mallocSize
        ptr = mallocBlock
    } else {
        print("\(title), \(ptr) (\(MemoryType(ptr).rawValue)), showing size: \(size) -> ")
    }
    let v = ptr.assumingMemoryBound(to: UInt8.self)
    for index in 0 ..< size {
        if index != 0 && (index % 32) == 0 {
            print()
        }
        print(String(format: "%02x ", v[index]), terminator: "")
    }
    print()
}
 */
