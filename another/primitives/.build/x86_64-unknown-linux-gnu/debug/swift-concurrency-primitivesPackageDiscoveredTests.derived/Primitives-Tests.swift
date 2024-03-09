import XCTest
@testable import Primitives_Tests

fileprivate extension BufferedTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static let __allTests__BufferedTests = [
        ("test_blocking_queue", test_blocking_queue),
        ("test_blocking_queue_with_reverse_order", test_blocking_queue_with_reverse_order),
        ("test_buff_chan", test_buff_chan)
    ]
}

fileprivate extension PrimitivesTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static let __allTests__PrimitivesTests = [
        ("test_ThreadPool", test_ThreadPool),
        ("test_barrier", test_barrier),
        ("test_barrier_decrement_alone", test_barrier_decrement_alone),
        ("test_cancelling_pool_with_locked", test_cancelling_pool_with_locked),
        ("test_cancelling_singlethread", test_cancelling_singlethread),
        ("test_global_pool", asyncTest(test_global_pool)),
        ("test_latch", test_latch),
        ("test_latch_decrement_alone", test_latch_decrement_alone),
        ("test_lock", test_lock),
        ("test_locked", test_locked),
        ("test_locked_wrapper", test_locked_wrapper),
        ("test_once", test_once),
        ("test_oncestate", test_oncestate),
        ("test_pool_with_locked", test_pool_with_locked),
        ("test_queue", test_queue),
        ("test_queue_with_reverse_order", test_queue_with_reverse_order),
        ("test_singlethread", test_singlethread),
        ("test_thread_that_joins", test_thread_that_joins)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __Primitives_Tests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BufferedTests.__allTests__BufferedTests),
        testCase(PrimitivesTests.__allTests__PrimitivesTests)
    ]
}