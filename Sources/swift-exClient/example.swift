import Foundation

@_staticExclusiveOnly
struct NonCopyableExclusive: ~Copyable {
    var age: Int = 0
    init() {}
}

struct NonCopyable: ~Copyable {
    var age: Int = 0
    init() {}
}

// @_nonEscapable
struct NonEscapableType: Escapable {
    var age: Int = 0
    init() {}
}
