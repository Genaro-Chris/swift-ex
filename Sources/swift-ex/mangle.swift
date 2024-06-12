
// <unknown>:0: error: circular reference
// <unknown>:0: note: through reference here
// swift 6.0
@_silgen_name("swift_getTypeName")
public func _getTypeName(_ type: Any.Type, qualified: Bool) -> (UnsafePointer<UInt8>, Int)

func getTypeName(_ type: Any.Type, qualified: Bool) -> String {
    let (stringPtr, _) = _getTypeName(type, qualified: qualified)
    return String(cString: stringPtr)
}

func printMem<T>(_ of: T.Type) {
    //let name = _mangledTypeName(of)!

    let name = getTypeName(of, qualified: true)  
    //let type =  _typeByName(name)
    print("Size \(name): \(MemoryLayout<T>.size)")
    print("Alignment of \(name): \(MemoryLayout<T>.alignment)")
    print("Stride of \(name): \(MemoryLayout<T>.stride)")
}
