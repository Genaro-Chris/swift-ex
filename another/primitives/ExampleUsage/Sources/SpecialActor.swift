import Foundation

actor SpecialActor {

    private let executor = SerialJobExecutor()

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: executor)
    }

    nonisolated func pollAll() {
        executor.pollAll()
    }

    private var count_ = 0

    func increment(by: Int) {
        count_ += by
    }

    var count: Int {
        count_
    }
}