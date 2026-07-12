import XCTest
@testable import TLNHours

final class HATimestampTests: XCTestCase {
    func testParsesWithMicrosecondsAndOffset() {
        let date = HATimestamp.parse("2026-07-10T17:18:13.205962+02:00")
        XCTAssertNotNil(date)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 2 * 3600)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 17)
        XCTAssertEqual(components.minute, 18)
        XCTAssertEqual(components.second, 13)
    }

    func testParsesWithoutFractionalSeconds() {
        XCTAssertNotNil(HATimestamp.parse("2026-07-10T17:18:13+00:00"))
    }

    func testReturnsNilForGarbage() {
        XCTAssertNil(HATimestamp.parse("not a date"))
    }
}
