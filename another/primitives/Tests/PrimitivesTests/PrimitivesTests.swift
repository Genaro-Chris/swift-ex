import XCTest

@testable import Primitives

final class PrimitivesTests: XCTestCase {

    func test_thread_that_joins() {
        @Locked var count = 0
        let thread = UniqueThread {
            count = Int.random(in: 10 ... 100)
        }

        thread.join()

        XCTAssert(count > 10)
    }

    func test_queue() {
        let queue = Queue<String>(order: .firstOut)

        (0 ... 9).forEach { [queue] i in
            queue.enqueue("\(i)")
        }

        let expected = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map { String($0) }

        let result: [String] = queue.map { $0 }

        XCTAssertEqual(result, expected)

        XCTAssertEqual(result.count, 10)
    }

    func test_queue_with_reverse_order() {
        let queue = Queue<String>(order: .lastOut)

        (0 ... 9).reversed().forEach { [queue] i in
            queue.enqueue("\(i)")
        }

        let expected = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map { String($0) }

        let result: [String] = queue.map { $0 }

        XCTAssertEqual(result, expected)

        XCTAssertEqual(result.count, 10)
    }

    func test_latch() {
        var queue = 0
        let latch = Latch(count: 10)!
        let lock = Lock()
        for value in 1 ... 10 {
            Thread {
                lock.whileLocked {
                    queue += value
                }
                latch.decrementAndWait()
            }.start()
        }
        latch.waitForAll()

        XCTAssertEqual(queue, 55)
    }

    func test_latch_decrement_alone() {
        var queue = 0
        let latch = Latch(count: 11)!
        let lock = Lock()
        for value in 1 ... 10 {
            Thread {
                lock.whileLocked {
                    queue += value
                }
                latch.decrementAndWait()
            }.start()
        }
        latch.decrementAlone()
        latch.waitForAll()

        XCTAssertEqual(queue, 55)
    }

    func test_barrier() {
        let barrier = Barrier(count: 2)
        let lock = Lock()
        var total = 0
        XCTAssertNotNil(barrier)
        let threads = (1 ... 9).map { i in
            UniqueThread {
                lock.whileLocked {
                    total += 1
                }
                print("Wait blocker \(i)")
                barrier?.decrementAndWait()
                print("After blocker \(i)")
            }
        }

        lock.whileLocked {
            total += 1
        }
        print("Wait blocker \(10)")
        barrier?.decrementAndWait()
        threads.forEach { $0.join() }
        print("After blocker \(10)")
        XCTAssertEqual(total, 10)
    }

    func test_barrier_decrement_alone() {
        let barrier = Barrier(count: 5)
        let lock = Lock()
        var total = 0
        let threads = (1 ... 9).map { i in
            UniqueThread {
                lock.whileLocked {
                    total += 1
                }
                print("Wait blocker \(i)")
                barrier?.decrementAndWait()
                print("After blocker \(i)")
            }
        }
        lock.whileLocked {
            total += 1
        }
        print("Wait blocker \(10)")
        barrier?.decrementAlone()
        barrier?.waitForAll()
        threads.forEach { $0.join() }
        print("After blocker \(10)")
        XCTAssertEqual(total, 10)
    }

    func test_once() {
        var total = 0
        DispatchQueue.concurrentPerform(iterations: 6) { _ in
            Once.runOnce {
                total += 1
            }
        }
        XCTAssertEqual(total, 1)
    }

    func test_oncestate() {
        var total = 0
        let once = OnceState()
        DispatchQueue.concurrentPerform(iterations: 6) { _ in
            once.runOnce {
                total += 1
            }
        }
        XCTAssertEqual(total, 1)
    }

    func test_lock() {
        var total = 0
        let lock = Lock()
        DispatchQueue.concurrentPerform(iterations: 11) { i in
            lock.whileLocked {
                total += i
            }
        }
        XCTAssertEqual(total, 55)
    }

    func test_locked() {
        struct Student {
            var age: Int
            var scores: [Int]
        }
        let student = Locked(Student(age: 0, scores: []))
        DispatchQueue.concurrentPerform(iterations: 10) { i in
            student.updateWhileLocked { student in
                student.scores.append(i)
            }
            if i == 9 {
                student.age = 18
            }
        }

        XCTAssertEqual(student.scores.count, 10)
        XCTAssertEqual(student.age, 18)
    }

    func test_locked_wrapper() {
        struct Student {
            var age: Int
            var scores: [Int]
        }
        @Locked var student = Student(age: 0, scores: [])
        DispatchQueue.concurrentPerform(iterations: 10) { i in
            $student.updateWhileLocked { student in
                student.scores.append(i)
            }
            if i == 9 {
                student.age = 18
            }
        }

        XCTAssertEqual(student.scores.count, 10)
        XCTAssertEqual(student.age, 18)
    }

    func test_pool_with_locked() {

        @Locked var total = 0
        do {
            let pool = ThreadPool(count: 4, waitType: .waitForAll)!
            for i in 1 ... 10 {
                pool.submit {
                    $total.updateWhileLocked { $0 += i }
                }
            }
        }

        XCTAssertEqual(total, 55)
    }

    func test_cancelling_pool_with_locked() {

        @Locked var total = 0
        do {
            let pool = ThreadPool(count: 3, waitType: .cancelAll)!
            for i in 1 ... 10 {
                pool.submit {
                    Thread.sleep(forTimeInterval: 0.1)
                    $total.updateWhileLocked { $0 += i }
                }
            }
        }

        XCTAssertNotEqual(total, 55)
    }

    func test_singlethread() {
        @Locked var total = 0
        let handle = SingleThread()
        for i in 1 ... 10 {
            handle.submit {
                $total.updateWhileLocked { $0 += i }
            }
        }
        handle.pollAll()
        XCTAssertEqual(total, 55)
    }

    func test_cancelling_singlethread() {
        @Locked var total = 0
        do {
            let handle = SingleThread(waitType: .cancelAll)
            for i in 1 ... 10 {
                handle.submit {
                    $total.updateWhileLocked { $0 += i }
                }
            }
        }
        XCTAssertNotEqual(total, 55)
    }

    func test_ThreadPool() {
        @Locked var total = 0
        let pool = ThreadPool(count: 4)
        for i in 1 ... 10 {
            pool?.submit {
                Thread.sleep(forTimeInterval: 1)
                $total.updateWhileLocked { $0 += i }
            }
        }
        pool?.pollAll()
        XCTAssertEqual(total, 55)
    }

    func test_global_pool() async {
        @Locked var total = 0
        for i in 1 ... 10 {
            ThreadPool.globalPool.submit {
                Thread.sleep(forTimeInterval: 1)
                $total.updateWhileLocked { $0 += i }
            }
        }
        ThreadPool.globalPool.pollAll()
        XCTAssertEqual(total, 55)
    }
}
