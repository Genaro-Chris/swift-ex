import XCTest
import Testing

@Suite("SomeTest")
struct SomeTest {

    @Test("TestExample")
    func ex() {
        #expect(1 == 1)
    }
}


final class ATests: XCTestCase {
    func test_add() {
        XCTAssert(1 + 1 == 2)
    }

    func test_minus() {
        #expect(2 - 1 == 1)
    }

    func testAll() async {
        await XCTestScaffold.runAllTests(hostedBy: self)
    }
}