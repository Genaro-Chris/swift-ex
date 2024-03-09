import XCTest

@testable import Primitives

final class BufferedTests: XCTestCase {
    func test_buff_chan() {
        XCTAssert(true)
    }

    func test_blocking_queue() {
        let queue = Channel<String>(order: .firstOut)
        @Locked var counter = 0
        let pool = ThreadPool(count: 5, waitType: .waitForAll)!
        (0 ... 9).forEach { i in
            pool.submit { [queue] in
                queue.enqueue("\(i)")
                $counter.updateWhileLocked {
                    $0 += 1
                }
            }
        }

        let handle = SingleThread()
        handle.submit {
            while counter < 10 {}
            queue.cancelQueue()
        }

        let expected = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map { String($0) }

        let result: [String] = queue.map {
            return $0
        }.sorted()

        XCTAssertEqual(result, expected)

        XCTAssertEqual(result.count, 10)
    }

    func test_blocking_queue_with_reverse_order() {
        let queue = Channel<String>(order: .lastOut)

        @Locked var counter = 0
        let pool = ThreadPool(count: 5, waitType: .waitForAll)!
        (0 ... 9).forEach { i in
            pool.submit { [queue] in
                queue.enqueue("\(i)")
                $counter.updateWhileLocked {
                    $0 += 1
                }
            }
        }

        let handle = SingleThread()
        handle.submit {
            while counter < 10 {}
            queue.cancelQueue()
        }

        let expected = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].reversed().map { String($0) }

        let result: [String] = queue.map { $0 }.sorted().reversed()

        XCTAssertEqual(result, expected)

        XCTAssertEqual(result.count, 10)

    }
}
