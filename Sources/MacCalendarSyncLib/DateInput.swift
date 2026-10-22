import Foundation

/// A date given as input, either as an absolute date or as an offset in days from today.
public enum DateInput: Equatable, Sendable {
    case absolute(Date)
    /// Offset in days relative to today; `0` means today
    case relative(days: Int)

    /// Parses one of:
    /// - `today` or `0`
    /// - an offset in days or weeks, such as `-1d`, `+30d` or `2w`
    /// - an absolute date in format ``INPUT_DATE_FORMAT``
    public init?(_ string: String, calendar: Calendar = .current) {
        let value = string.trimmingCharacters(in: .whitespaces).lowercased()
        if value == "today" || value == "0" {
            self = .relative(days: 0)
            return
        }

        if let match = value.wholeMatch(of: /([+-]?)(\d+)([dw])/) {
            guard let amount = Int(match.2) else { return nil }
            let (days, overflow) = amount.multipliedReportingOverflow(by: match.3 == "w" ? 7 : 1)
            guard !overflow else { return nil }
            self = .relative(days: match.1 == "-" ? -days : days)
            return
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = INPUT_DATE_FORMAT
        guard let date = formatter.date(from: string) else { return nil }
        self = .absolute(date)
    }
}

public enum DateRangeError: Error, Equatable, CustomStringConvertible {
    /// The end of the range is a negative offset, i.e. it is in the past
    case negativeRelativeEnd(days: Int)
    /// The end of the range comes before its start
    case endBeforeStart(start: Date, end: Date)
    /// The offset is too large to be represented as a date
    case outOfRange

    public var description: String {
        switch self {
        case .negativeRelativeEnd(let days):
            return "End date offset must not be negative; got \(days) day(s)"
        case .endBeforeStart(let start, let end):
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = INPUT_DATE_FORMAT
            return
                "End date (\(formatter.string(from: end))) must not be before start date (\(formatter.string(from: start)))"
        case .outOfRange:
            return "Date offset is out of range"
        }
    }
}

/// Resolves start and end inputs into concrete dates.
///
/// Relative inputs are anchored to the start of the day in the calendar's time zone: a relative start
/// resolves to 00:00:00 of that day and a relative end resolves to 23:59:59 of that day, so `0` to `0`
/// covers all of today.
public func resolveDateRange(
    start: DateInput,
    end: DateInput,
    now: Date = .now,
    calendar: Calendar = .current
) throws(DateRangeError) -> (start: Date, end: Date) {
    if case .relative(let days) = end, days < 0 {
        throw .negativeRelativeEnd(days: days)
    }

    func startOfDay(offset days: Int) throws(DateRangeError) -> Date {
        guard let date = calendar.date(byAdding: .day, value: days, to: now) else {
            throw .outOfRange
        }
        return calendar.startOfDay(for: date)
    }

    let startDate: Date
    switch start {
    case .absolute(let date):
        startDate = date
    case .relative(let days):
        startDate = try startOfDay(offset: days)
    }

    let endDate: Date
    switch end {
    case .absolute(let date):
        endDate = date
    case .relative(let days):
        // Last second of the day, matching the `23:59:59` convention used for absolute end dates
        let (nextDay, overflow) = days.addingReportingOverflow(1)
        guard !overflow else { throw .outOfRange }
        endDate = try startOfDay(offset: nextDay).addingTimeInterval(-1)
    }

    guard endDate >= startDate else {
        throw .endBeforeStart(start: startDate, end: endDate)
    }
    return (startDate, endDate)
}
