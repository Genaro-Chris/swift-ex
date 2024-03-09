import Foundation
import Primitives

final class SerialJobExecutor: SerialExecutor {

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    func pollAll() {
        threadHandle.pollAll()
    }

    init() {}

    private let threadHandle = SingleThread(waitType: .waitForAll)

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedSerialExecutor()
        threadHandle.submit {
            job.runSynchronously(on: executor)
        }
    }

}
