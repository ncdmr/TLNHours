import XCTest
@testable import TLNHours

final class WorkSessionTests: XCTestCase {
    func testAwayWhenStateIsNotWork() {
        let status = WorkSession.compute(state: "not_home", lastChanged: Date(), now: Date())
        XCTAssertEqual(status, .away)
    }

    func testAtWorkBeforeTargets() throws {
        let now = Date()
        let arrived = now.addingTimeInterval(-2 * 3600) // arrived 2h ago
        let status = WorkSession.compute(state: "Work", lastChanged: arrived, now: now)

        guard case .atWork(let resolvedArrived, let diff8h, let diff830) = status else {
            return XCTFail("expected .atWork")
        }
        XCTAssertEqual(resolvedArrived, arrived)
        XCTAssertEqual(diff8h, -6 * 3600, accuracy: 1)
        XCTAssertEqual(diff830, -6.5 * 3600, accuracy: 1)
    }

    func testAtWorkExactlyAtEightHours() throws {
        let now = Date()
        let arrived = now.addingTimeInterval(-8 * 3600)
        let status = WorkSession.compute(state: "Work", lastChanged: arrived, now: now)

        guard case .atWork(_, let diff8h, let diff830) = status else {
            return XCTFail("expected .atWork")
        }
        XCTAssertEqual(diff8h, 0, accuracy: 1)
        XCTAssertEqual(diff830, -1800, accuracy: 1)
    }

    func testAtWorkPastBothTargets() throws {
        let now = Date()
        let arrived = now.addingTimeInterval(-9 * 3600) // 1h over the 8h30 target
        let status = WorkSession.compute(state: "Work", lastChanged: arrived, now: now)

        guard case .atWork(_, let diff8h, let diff830) = status else {
            return XCTFail("expected .atWork")
        }
        XCTAssertEqual(diff8h, 3600, accuracy: 1)
        XCTAssertEqual(diff830, 1800, accuracy: 1)
    }

    func testFormatDiffUnderTarget() {
        XCTAssertEqual(WorkSession.formatDiff(-2 * 3600 - 45 * 60), "-2h45m")
    }

    func testFormatDiffOverTarget() {
        XCTAssertEqual(WorkSession.formatDiff(3600 + 5 * 60), "+1h05m")
    }

    func testFormatDiffAtZero() {
        XCTAssertEqual(WorkSession.formatDiff(0), "+0h00m")
    }

    func testTargetTimeIsArrivalPlusOffset() {
        let arrived = Date(timeIntervalSince1970: 0)
        let leave8h = WorkSession.targetTime(arrived: arrived, target: WorkSession.target8h)
        let leave830 = WorkSession.targetTime(arrived: arrived, target: WorkSession.target830)

        XCTAssertEqual(leave8h.timeIntervalSince(arrived), 8 * 3600)
        XCTAssertEqual(leave830.timeIntervalSince(arrived), 8 * 3600 + 1800)
    }

    func testTimeLabelFormatsAsHHmm() {
        // WorkSession.timeLabel uses the system's current time zone, so just
        // check the shape rather than an exact value tied to a fixed zone.
        let label = WorkSession.timeLabel(Date())
        XCTAssertTrue(label.contains(":"))
        XCTAssertEqual(label.count, 5)
    }

    func testTransitionLogLineNilOnArrivalFromAway() {
        let now = Date()
        let current = WorkSession.compute(state: "Work", lastChanged: now, now: now)
        XCTAssertNil(WorkSession.transitionLogLine(previous: .away, current: current, now: now))
    }

    func testTransitionLogLineNilOnArrivalFromNilPrevious() {
        let now = Date()
        let current = WorkSession.compute(state: "Work", lastChanged: now, now: now)
        XCTAssertNil(WorkSession.transitionLogLine(previous: nil, current: current, now: now))
    }

    func testTransitionLogLineOnDeparture() {
        let calendar = Calendar.current
        let arrived = calendar.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 8, minute: 32))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 16, minute: 37))!
        let previous = WorkSession.compute(state: "Work", lastChanged: arrived, now: now)

        let line = WorkSession.transitionLogLine(previous: previous, current: .away, now: now)

        XCTAssertEqual(line, "2026-07-10-08:32-16:37-8h05m")
    }

    func testTransitionLogLineNilWhenStillAtWork() {
        let now = Date()
        let arrived = now.addingTimeInterval(-2 * 3600)
        let status = WorkSession.compute(state: "Work", lastChanged: arrived, now: now)
        XCTAssertNil(WorkSession.transitionLogLine(previous: status, current: status, now: now))
    }

    func testTransitionLogLineNilWhenStillAway() {
        XCTAssertNil(WorkSession.transitionLogLine(previous: .away, current: .away, now: Date()))
    }
}
