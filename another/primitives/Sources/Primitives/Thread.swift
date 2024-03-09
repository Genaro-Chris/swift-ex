import Atomics
import Foundation

///
public final class UniqueThread: Thread, @unchecked Sendable {

    private let latch: Latch

    private let threadName: String

    private let started: ManagedAtomic<Bool>

    var isBusyExecuting: Bool {
        isBusy.load(ordering: .relaxed)
    }

    private let isBusy: ManagedAtomic<Bool>

    private let block: () -> Void

    private let alreadyJoined: ManagedAtomic<Bool>

    private let special: Bool

    public override var name: String? {
        get {
            threadName
        }
        set {}
    }

    ///
    /// - Parameters:
    ///   - name:
    ///   - joinable:
    ///   - block:
    public init(
        name: String = "Thread",
        block: @escaping () -> Void
    ) {
        self.special = true
        self.latch = Latch(count: 1)!
        self.alreadyJoined = ManagedAtomic(false)
        self.threadName = name
        self.isBusy = ManagedAtomic(false)
        self.block = block
        self.started = ManagedAtomic(false)
        super.init()
        self.qualityOfService = .userInitiated
        self.start()
    }

    init(
        name: String,
        block: @escaping (ManagedAtomic<Bool>) -> Void
    ) {
        self.special = false
        self.latch = Latch(count: 1)!
        self.alreadyJoined = ManagedAtomic(false)
        self.threadName = name
        self.isBusy = ManagedAtomic(false)
        self.block = { [isBusy] in
            block(isBusy)
        }
        self.started = ManagedAtomic(false)
        super.init()
        self.qualityOfService = .userInitiated
        self.start()
    }

    public override func start() {
        guard !self.started.load(ordering: .relaxed) else {
            return
        }
        defer {
            self.started.store(true, ordering: .relaxed)
        }
        super.start()
    }

    public override func main() {
        if self.special {
            self.isBusy.store(true, ordering: .releasing)
            block()
            self.isBusy.store(false, ordering: .releasing)
        } else {
            block()
        }
        latch.decrementAndWait()
    }

    /// Block the caller's thread until the thread finishes
    public func join() {
        guard !alreadyJoined.load(ordering: .acquiring) else {
            return
        }
        latch.waitForAll()
        alreadyJoined.store(true, ordering: .releasing)
    }
}
