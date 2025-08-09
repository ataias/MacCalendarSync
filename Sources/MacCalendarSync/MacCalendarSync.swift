import ArgumentParser
import EventKit
import MacCalendarSyncLib

@main
struct MacCalendarSync: AsyncParsableCommand {
    @Flag(help: "Skips calendar mutations.")
    var dryRun = false

    @Flag(help: "Shows status information and what will be changed.")
    var verbose = false

    @Flag(help: "Redact event information before copying")
    var redact = false

    @Option(help: "Target calendar name; events from source calendar will be added to this one")
    var targetCalendarName: String

    @Option(help: "Source calendar name; events will be copied from this one into target")
    var sourceCalendarName: String

    @Option(help: "Start date in format \(INPUT_DATE_FORMAT)")
    var startDate: String

    @Option(help: "End date in format \(INPUT_DATE_FORMAT)")
    var endDate: String

    mutating func run() async throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = INPUT_DATE_FORMAT

        let eventStore = EKEventStore()
        try await eventStore.requestFullAccessToEvents()

        guard let startDate = formatter.date(from: startDate) else {
            fatalError(
                "Start date not valid; Format should be \(INPUT_DATE_FORMAT)")
        }
        guard let endDate = formatter.date(from: endDate) else {
            fatalError(
                "End date not valid; Format should be \(INPUT_DATE_FORMAT)")
        }

        let target = MyCalendar(
            eventStore: eventStore,
            title: targetCalendarName)
        let source = MyCalendar(
            eventStore: eventStore,
            title: sourceCalendarName)

        // TODO: when the copied redacted event is modified (start/endDate), it is not deleted; need to add a test there
        let diff = target.diff(
            source, start: startDate, end: endDate, redact: redact)

        if verbose {
            print(">>> Processing calendars:")
            print("    Source: \(sourceCalendarName)")
            print("    Target: \(targetCalendarName)")
            print(
                "    Period: \(DateFormatter.shortDate.string(from: startDate)) - \(DateFormatter.shortDate.string(from: endDate))"
            )
            print("")

            let synced = diff.synced.map(CalendarEvent.init)
            let add = diff.add.map(CalendarEvent.init)
            let remove = diff.remove.map(CalendarEvent.init)

            // Summary statistics
            print(">>> Summary:")
            print("    Already synced: \(synced.count) events")
            print("    To add: \(add.count) events")
            print("    To remove: \(remove.count) events")
            print("")

            // Show synced events if any
            if !synced.isEmpty {
                print(">>> synced:")
                for event in synced {
                    print(event.compactDescription)
                }
                print("")
            }

            // Show events to add if any
            if !add.isEmpty {
                print(">>> add:")
                for event in add {
                    print(event.compactDescription)
                }
                print("")
            }

            // Show events to remove if any
            if !remove.isEmpty {
                print(">>> remove:")
                for event in remove {
                    print(event.compactDescription)
                }
                print("")
            }
        }

        guard !dryRun else {
            return
        }

        for event in diff.add {
            try eventStore.save(event, span: .thisEvent)
        }
        for event in diff.remove {
            try eventStore.remove(event, span: .thisEvent)
        }
        try eventStore.commit()

    }
}

struct Config: Codable {
    var source: String
    var target: String
    var sync: Sync

    struct Calendar: Codable {
        var name: String
        var email: String
    }

    struct Sync: Codable {
        /// The start date to sync calendars; if not given, assumes today
        var startDate: String? = nil

        /// The end date to sync calendars; this or the property `days` must be set
        var endDate: String? = nil
        var days: Int? = nil
    }
}
