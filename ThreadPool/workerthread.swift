import Foundation

class WorkerThread: Thread {

    let latch: Latch

    let block: Tasks

    override func main() {
        block()
        latch.decrementAndWait()
    }

    func join() {
        latch.waitForAll()
    }

    init(_ body: @escaping Tasks) {
        block = body
        latch = Latch(value: 1)!
        super.init()
    }
}
