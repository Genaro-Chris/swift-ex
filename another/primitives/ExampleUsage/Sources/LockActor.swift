import Foundation

actor LockActor {

    private let executor = LockCustomExecutor()

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: executor)
    }

    private var count_ = 0

    func increment(by: Int) {
        count_ += by
    }

    var count: Int {
        count_
    }
}
