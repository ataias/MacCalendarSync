import Foundation
import Testing

@testable import MacCalendarSyncLib

@Suite("DateInput parsing")
struct DateInputParsingTests {
    @Test(arguments: [
        ("today", 0), ("TODAY", 0), ("0", 0),
        ("1d", 1), ("+30d", 30), ("-1d", -1), ("0d", 0),
        ("2w", 14), ("-1w", -7), ("+3W", 21),
    ])
    func parsesRelativeInputs(input: String, days: Int) {
        #expect(DateInput(input) == .relative(days: days))
    }

    @Test(arguments: ["", "1", "-1", "1m", "1 day", "d", "--1d", "1.5d", "99999999999999999999d"])
    func rejectsInvalidInputs(input: String) {
        #expect(DateInput(input) == nil)
    }

    @Test func parsesAbsoluteDate() throws {
        let calendar = makeCalendar()
        let input = try #require(DateInput("2025-02-10 08:30:00", calendar: calendar))
        #expect(input == .absolute(date(2025, 2, 10, 8, 30, 0, calendar)))
    }
}

@Suite("Date range resolution")
struct DateRangeResolutionTests {
    let calendar = makeCalendar()
    var now: Date { date(2026, 10, 22, 15, 30, 0, calendar) }

    @Test func todayCoversTheWholeDay() throws {
        let range = try resolveDateRange(
            start: .relative(days: 0), end: .relative(days: 0), now: now, calendar: calendar)
        #expect(range.start == date(2026, 10, 22, 0, 0, 0, calendar))
        #expect(range.end == date(2026, 10, 22, 23, 59, 59, calendar))
    }

    @Test func rollingWindowIsAnchoredToStartOfDay() throws {
        let range = try resolveDateRange(
            start: .relative(days: -1), end: .relative(days: 30), now: now, calendar: calendar)
        #expect(range.start == date(2026, 10, 21, 0, 0, 0, calendar))
        #expect(range.end == date(2026, 11, 21, 23, 59, 59, calendar))
    }

    @Test func handlesDaylightSavingTimeTransition() throws {
        // DST ends in New York on 2026-11-01
        let range = try resolveDateRange(
            start: .relative(days: 0), end: .relative(days: 14), now: now, calendar: calendar)
        #expect(range.end == date(2026, 11, 5, 23, 59, 59, calendar))
    }

    @Test func mixesAbsoluteAndRelative() throws {
        let start = date(2026, 10, 1, 0, 0, 0, calendar)
        let range = try resolveDateRange(
            start: .absolute(start), end: .relative(days: 1), now: now, calendar: calendar)
        #expect(range.start == start)
        #expect(range.end == date(2026, 10, 23, 23, 59, 59, calendar))
    }

    @Test func rejectsNegativeRelativeEnd() {
        #expect(throws: DateRangeError.negativeRelativeEnd(days: -1)) {
            try resolveDateRange(
                start: .relative(days: -7), end: .relative(days: -1), now: now, calendar: calendar)
        }
    }

    @Test func rejectsEndBeforeStart() {
        #expect(throws: DateRangeError.endBeforeStart(
            start: date(2026, 10, 27, 0, 0, 0, calendar),
            end: date(2026, 10, 23, 23, 59, 59, calendar))
        ) {
            try resolveDateRange(
                start: .relative(days: 5), end: .relative(days: 1), now: now, calendar: calendar)
        }
    }

    @Test func rejectsAbsoluteEndBeforeRelativeStart() {
        #expect(throws: DateRangeError.self) {
            try resolveDateRange(
                start: .relative(days: 0), end: .absolute(date(2026, 10, 1, 0, 0, 0, calendar)),
                now: now, calendar: calendar)
        }
    }
}

private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    return calendar
}

private func date(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int, _ calendar: Calendar
) -> Date {
    calendar.date(
        from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
}
