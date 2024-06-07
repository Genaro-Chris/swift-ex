import Foundation
import Builtin
import Synchronization


func sync() {
    _ = Synchronization.Atomic.init(56).exchange(43, ordering: .sequentiallyConsistent)
}

/* 
swift: swiftc  -O -emit-assembly -module-name output test.swift | swift demangle
swiftc  -O -emit-sil -module-name output test.swift | swift demangle
-Xfrontend -enable-ossa-modules
*/