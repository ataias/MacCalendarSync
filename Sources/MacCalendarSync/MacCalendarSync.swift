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

    @Option(help: "Number of days to sync from today; defaults to 28")
    var days: Int = 28

    mutating func run() async throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = INPUT_DATE_FORMAT

        let eventStore = EKEventStore()
        try await eventStore.requestFullAccessToEvents()

        let startDate = Date().addingTimeInterval(-4 * 60 * 60)
        let endDate = Date().addingTimeInterval(TimeInterval(days) * 24 * 60 * 60)

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
            let synced = diff.synced.map(CalendarEvent.init)
            print(">>> synced: \n")
            for event in synced {
                print(event.shortDescription)
            }

            let add = diff.add.map(CalendarEvent.init)
            print("")
            print(">>> add: \n")
            for event in add {
                print(event.shortDescription)
            }

            let remove = diff.remove.map(CalendarEvent.init)
            print("")
            print(">>> remove: \n")
            for event in remove {
                print(event.shortDescription)
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
