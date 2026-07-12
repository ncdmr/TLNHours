import XCTest
@testable import TLNHours

final class WorkLogTests: XCTestCase {
    var fileURL: URL!

    override func setUp() {
        super.setUp()
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".log")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    func testReadReturnsEmptyStringWhenFileMissing() {
        let log = WorkLog(fileURL: fileURL)
        XCTAssertEqual(log.read(), "")
    }

    func testAppendCreatesFileWithHeaderCommentThenLine() {
        let log = WorkLog(fileURL: fileURL)
        log.append("first line")
        XCTAssertEqual(log.read(), "\(WorkLog.headerComment)\nfirst line\n")
    }

    func testAppendMultipleLinesAccumulatesWithoutRepeatingHeader() {
        let log = WorkLog(fileURL: fileURL)
        log.append("first")
        log.append("second")
        XCTAssertEqual(log.read(), "\(WorkLog.headerComment)\nfirst\nsecond\n")
    }
}
