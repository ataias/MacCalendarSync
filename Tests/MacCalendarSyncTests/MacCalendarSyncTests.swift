import EventKit
import Testing

@testable import MacCalendarSyncLib

@Suite("CalendarSyncTests - Non Redacted")
struct CalendarSyncNonRedactedTests {
    let eventStore: EKEventStore
    let formatter: ISO8601DateFormatter
    let calendar1: MyCalendar
    let calendar2: MyCalendar
    let startDate: Date
    let endDate: Date

    init() async throws {
        self.formatter = ISO8601DateFormatter()

        self.eventStore = MockEventStore()
        let calendar1 = try makeCalendar(
            eventStore: eventStore, title: "Test Calendar 1")
        try makeEvent(
            eventStore: eventStore,
            title: "Event 1",
            calendar: calendar1,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )
        try makeEvent(
            eventStore: eventStore,
            title: "Some Event in Calendar 1",
            calendar: calendar1,
            from: "2023-01-01T08:00:00Z",
            to: "2023-01-01T09:00:00Z"
        )
        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL] Unknown 1",
            calendar: calendar1,
            from: "2023-01-01T08:00:00Z",
            to: "2023-01-01T09:00:00Z"
        )

        let calendar2 = try makeCalendar(
            eventStore: eventStore,
            title: "Test Calendar 2"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL] Event 1",
            calendar: calendar2,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL] Unknown 2",
            calendar: calendar2,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "Some Event in Calendar 2",
            calendar: calendar2,
            from: "2023-01-01T09:00:00Z",
            to: "2023-01-01T10:00:00Z"
        )

        self.calendar1 = MyCalendar(
            eventStore: eventStore,
            title: calendar1.title
        )
        self.calendar2 = MyCalendar(
            eventStore: eventStore, title: calendar2.title)

        self.startDate = formatter.date(from: "2023-01-01T00:00:00Z")!
        self.endDate = formatter.date(from: "2023-01-01T23:23:59Z")!
    }

    @Test func identifiesNonRedactedSyncedEventsFromCalendar1To2() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: false)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "Event 1")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T11:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesNonRedactedSyncedEventsFromCalendar2To1() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: false)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "[EXTERNAL] Event 1")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T11:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesNonRedactedAddEventsFromCalendar1To2() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: false)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        #expect(event.title == "[EXTERNAL] Some Event in Calendar 2")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T09:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesNonRedactedAddEventsFromCalendar2To1() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: false)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        #expect(event.title == "[EXTERNAL] Some Event in Calendar 1")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T08:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T09:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesNonRedactedRemoveEventsFromCalendar1To2() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: false)
        try #require(diff.remove.count == 1)
        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 1")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T08:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T09:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesNonRedactedRemoveEventsFromCalendar2To1() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: false)
        try #require(diff.remove.count == 1)
        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 2")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T11:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }
}

@Suite("CalendarSyncTests - Redacted")
struct CalendarSyncRedactedTests {
    let eventStore: EKEventStore
    let formatter: ISO8601DateFormatter
    let calendar1: MyCalendar
    let calendar2: MyCalendar
    let startDate: Date
    let endDate: Date

    init() async throws {
        self.formatter = ISO8601DateFormatter()

        self.eventStore = MockEventStore()
        let calendar1 = try makeCalendar(
            eventStore: eventStore, title: "Test Calendar 1")
        try makeEvent(
            eventStore: eventStore,
            title: "Event 1",
            calendar: calendar1,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )
        try makeEvent(
            eventStore: eventStore,
            title: "Some Event in Calendar 1",
            calendar: calendar1,
            from: "2023-01-01T08:00:00Z",
            to: "2023-01-01T09:00:00Z"
        )
        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL] Unknown 1",
            calendar: calendar1,
            from: "2023-01-01T08:00:00Z",
            to: "2023-01-01T09:00:00Z"
        )

        let calendar2 = try makeCalendar(
            eventStore: eventStore,
            title: "Test Calendar 2"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL]",
            calendar: calendar2,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z",
            notes: "\n\n[BASE_HASH]52e0244b3943f027009ee88ce8345d100f1d282e1a153f931e1d02c30688c051"
        )

        // The following event has the same hash as the previous one, but a different start/end time; it should be removed later on
        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL]",
            calendar: calendar1,  // intentionally on calendar1
            from: "2023-01-01T13:00:00Z",
            to: "2023-01-01T14:00:00Z",
            notes: "\n\n[BASE_HASH]52e0244b3943f027009ee88ce8345d100f1d282e1a153f931e1d02c30688c051"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL] Unknown 2",
            calendar: calendar2,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "Some Event in Calendar 2",
            calendar: calendar2,
            from: "2023-01-01T09:00:00Z",
            to: "2023-01-01T10:00:00Z"
        )

        self.calendar1 = MyCalendar(
            eventStore: eventStore,
            title: calendar1.title
        )
        self.calendar2 = MyCalendar(
            eventStore: eventStore, title: calendar2.title)

        self.startDate = formatter.date(from: "2023-01-01T00:00:00Z")!
        self.endDate = formatter.date(from: "2023-01-01T23:23:59Z")!
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar1To2() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: true)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "Event 1")
        #expect(event.notes == nil)
        print(event.hash())

        let eventStartDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T11:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar2To1() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: true)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "[EXTERNAL]")
        #expect(
            event.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]52e0244b3943f027009ee88ce8345d100f1d282e1a153f931e1d02c30688c051")

        let eventStartDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T11:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesRedactedAddEventsFromCalendar1To2() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: true)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        // We should have the hash of "Some Calendar Event 2"
        #expect(event.title == "[EXTERNAL]")
        #expect(
            event.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]156105adbf6c574ff1b89ccad689faf1475ecaf6dbd0d304c0ef0289a25a7311")

        let eventStartDate: Date = formatter.date(from: "2023-01-01T09:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesRedactedAddEventsFromCalendar2To1() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: true)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        // We should have the hash of "Some Event in Calendar 1"
        #expect(event.title == "[EXTERNAL]")
        #expect(
            event.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]31dc3df45d0beccff67ca1e4ba39eb04b906e1756bcf2aac9e543c5929ae0d59")

        let eventStartDate: Date = formatter.date(from: "2023-01-01T08:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T09:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }

    @Test func identifiesRedactedRemoveEventsFromCalendar1To2() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: true)
        try #require(diff.remove.count == 1)

        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 1")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T08:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T09:00:00Z")!
        #expect(event.endDate == eventEndDate)

    }

    @Test func identifiesRedactedRemoveEventsFromCalendar2To1() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: true)
        try #require(diff.remove.count == 1)
        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 2")
        #expect(event.notes == nil)

        let eventStartDate: Date = formatter.date(from: "2023-01-01T10:00:00Z")!
        #expect(event.startDate == eventStartDate)
        let eventEndDate: Date = formatter.date(from: "2023-01-01T11:00:00Z")!
        #expect(event.endDate == eventEndDate)
    }
}

@Suite("ForwardedEventTests - FW: Prefix")
struct ForwardedEventTests {
    let eventStore: EKEventStore
    let formatter: ISO8601DateFormatter
    let calendar1: MyCalendar
    let calendar2: MyCalendar
    let startDate: Date
    let endDate: Date

    init() async throws {
        self.formatter = ISO8601DateFormatter()

        self.eventStore = MockEventStore()
        let calendar1 = try makeCalendar(
            eventStore: eventStore, title: "Test Calendar 1")

        try makeEvent(
            eventStore: eventStore,
            title: "FW: Meeting with Client",
            calendar: calendar1,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "FW: Team Standup",
            calendar: calendar1,
            from: "2023-01-01T14:00:00Z",
            to: "2023-01-01T15:00:00Z"
        )

        let calendar2 = try makeCalendar(
            eventStore: eventStore,
            title: "Test Calendar 2"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "Meeting with Client",
            calendar: calendar2,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL] Team Standup",
            calendar: calendar2,
            from: "2023-01-01T14:00:00Z",
            to: "2023-01-01T15:00:00Z"
        )

        self.calendar1 = MyCalendar(
            eventStore: eventStore,
            title: calendar1.title
        )
        self.calendar2 = MyCalendar(
            eventStore: eventStore, title: calendar2.title)

        self.startDate = formatter.date(from: "2023-01-01T00:00:00Z")!
        self.endDate = formatter.date(from: "2023-01-01T23:23:59Z")!
    }

    @Test func identifiesSyncedEventsWithFWPrefix() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: false)
        try #require(diff.synced.count == 2)

        // Check that FW: prefixed events are properly synced with non-FW: events
        let syncedTitles = diff.synced.map { $0.title }.sorted()
        #expect(syncedTitles.contains("FW: Meeting with Client"))
        #expect(syncedTitles.contains("FW: Team Standup"))
    }

    @Test func identifiesSyncedEventsWithoutFWPrefix() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: false)
        try #require(diff.synced.count == 2)

        // Check that non-FW: events are properly synced with FW: prefixed events
        let syncedTitles = diff.synced.map { $0.title }.sorted()
        #expect(syncedTitles.contains("Meeting with Client"))
        #expect(syncedTitles.contains("[EXTERNAL] Team Standup"))
    }
}

@Suite("ForwardedEventTests - FW: Prefix Redacted")
struct ForwardedEventRedactedTests {
    let eventStore: EKEventStore
    let formatter: ISO8601DateFormatter
    let calendar1: MyCalendar
    let calendar2: MyCalendar
    let startDate: Date
    let endDate: Date

    init() async throws {
        self.formatter = ISO8601DateFormatter()

        self.eventStore = MockEventStore()
        let calendar1 = try makeCalendar(
            eventStore: eventStore, title: "Test Calendar 1")

        // Create an event with FW: prefix that will be redacted
        try makeEvent(
            eventStore: eventStore,
            title: "FW: Meeting with Client",
            calendar: calendar1,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z"
        )

        // Create another event with FW: prefix for redaction
        try makeEvent(
            eventStore: eventStore,
            title: "FW: Team Standup",
            calendar: calendar1,
            from: "2023-01-01T14:00:00Z",
            to: "2023-01-01T15:00:00Z"
        )

        let calendar2 = try makeCalendar(
            eventStore: eventStore,
            title: "Test Calendar 2"
        )

        // For redacted tests, we need the hash of the title WITHOUT the FW: prefix
        // Create temp events to get the correct hashes
        let tempEvent1 = EKEvent(eventStore: eventStore)
        tempEvent1.title = "Meeting with Client"
        tempEvent1.startDate = formatter.date(from: "2023-01-01T10:00:00Z")!
        tempEvent1.endDate = formatter.date(from: "2023-01-01T11:00:00Z")!

        let tempEvent2 = EKEvent(eventStore: eventStore)
        tempEvent2.title = "Team Standup"
        tempEvent2.startDate = formatter.date(from: "2023-01-01T14:00:00Z")!
        tempEvent2.endDate = formatter.date(from: "2023-01-01T15:00:00Z")!

        // Create corresponding redacted events with BASE_HASH
        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL]",
            calendar: calendar2,
            from: "2023-01-01T10:00:00Z",
            to: "2023-01-01T11:00:00Z",
            notes: "\n\n[BASE_HASH]\(tempEvent1.hash())"
        )

        try makeEvent(
            eventStore: eventStore,
            title: "[EXTERNAL]",
            calendar: calendar2,
            from: "2023-01-01T14:00:00Z",
            to: "2023-01-01T15:00:00Z",
            notes: "\n\n[BASE_HASH]\(tempEvent2.hash())"
        )

        self.calendar1 = MyCalendar(
            eventStore: eventStore,
            title: calendar1.title
        )
        self.calendar2 = MyCalendar(
            eventStore: eventStore, title: calendar2.title)

        self.startDate = formatter.date(from: "2023-01-01T00:00:00Z")!
        self.endDate = formatter.date(from: "2023-01-01T23:23:59Z")!
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar1To2WithFWPrefix() async throws {
        let diff = calendar1.diff(
            calendar2, start: startDate, end: endDate, redact: true)
        try #require(diff.synced.count == 2)

        // Verify that FW: prefixed events are properly synced in redacted mode
        let syncedTitles = diff.synced.map { $0.title }.sorted()
        #expect(syncedTitles.contains("FW: Meeting with Client"))
        #expect(syncedTitles.contains("FW: Team Standup"))
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar2To1WithFWPrefix() async throws {
        let diff = calendar2.diff(
            calendar1, start: startDate, end: endDate, redact: true)
        try #require(diff.synced.count == 2)

        // Create temp events to verify expected hashes
        let tempEvent1 = EKEvent(eventStore: eventStore)
        tempEvent1.title = "Meeting with Client"
        tempEvent1.startDate = formatter.date(from: "2023-01-01T10:00:00Z")!
        tempEvent1.endDate = formatter.date(from: "2023-01-01T11:00:00Z")!

        let tempEvent2 = EKEvent(eventStore: eventStore)
        tempEvent2.title = "Team Standup"
        tempEvent2.startDate = formatter.date(from: "2023-01-01T14:00:00Z")!
        tempEvent2.endDate = formatter.date(from: "2023-01-01T15:00:00Z")!

        // Verify that redacted events are properly synced with FW: prefixed originals
        let syncedEvents = diff.synced.sorted { $0.startDate < $1.startDate }

        #expect(syncedEvents[0].title == "[EXTERNAL]")
        #expect(
            syncedEvents[0].notes?.trimmingCharacters(in: .whitespacesAndNewlines) == "[BASE_HASH]\(tempEvent1.hash())")

        #expect(syncedEvents[1].title == "[EXTERNAL]")
        #expect(
            syncedEvents[1].notes?.trimmingCharacters(in: .whitespacesAndNewlines) == "[BASE_HASH]\(tempEvent2.hash())")
    }
}

func makeCalendar(eventStore: EKEventStore, title: String) throws -> EKCalendar {
    let calendar = EKCalendar(
        for: .event,
        eventStore: eventStore
    )
    calendar.title = title

    try eventStore.saveCalendar(calendar, commit: true)

    return calendar
}

func makeEvent(
    eventStore: EKEventStore,
    title: String,
    calendar: EKCalendar,
    from: String,
    to: String,
    notes: String? = nil
) throws {
    let formatter = ISO8601DateFormatter()
    let event = EKEvent(eventStore: eventStore)
    event.calendar = calendar
    event.title = title
    event.startDate = formatter.date(from: from)!
    event.endDate = formatter.date(from: to)!
    event.alarms = []
    event.notes = notes
    try eventStore.save(event, span: .thisEvent, commit: true)
}

class MockEventStore: EKEventStore {
    private var calendars: Set<EKCalendar> = []
    private var eventIdToEvent: [String: EKEvent] = [:]

    override func calendars(for entityType: EKEntityType) -> [EKCalendar] {
        switch entityType {
        case .event:
            return Array(calendars)
        default:
            return []
        }
    }

    override func predicateForEvents(
        withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?
    ) -> NSPredicate {
        return MyCalendarPredicate(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
    }

    override func events(matching predicate: NSPredicate) -> [EKEvent] {

        return Array(eventIdToEvent.values).filter {
            return predicate.evaluate(with: $0)
        }
    }

    override func saveCalendar(_ calendar: EKCalendar, commit: Bool) throws {
        calendars.insert(calendar)
    }

    override func save(_ event: EKEvent, span: EKSpan) throws {
        guard event.calendar != nil else {
            throw NSError(domain: "Missing calendar for event", code: 0)
        }
        let id = "\(event.calendar.title)--\(event.title!)--\(String(describing: event.startDate))"
        eventIdToEvent[id] = event
    }

    override func save(_ event: EKEvent, span: EKSpan, commit: Bool) throws {
        try save(event, span: span)
    }
}

class MyCalendarPredicate: NSPredicate {
    let startDate: Date
    let endDate: Date
    let calendars: [EKCalendar]?
    init(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) {
        self.startDate = startDate
        self.endDate = endDate
        self.calendars = calendars
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var predicateFormat: String {
        "true"
    }

    override func evaluate(with object: Any?) -> Bool {
        if let event = object as? EKEvent {
            return event.startDate >= startDate && event.endDate <= endDate
                && (calendars == nil
                    || (calendars ?? []).contains(where: { calendar in
                        calendar.title == event.calendar.title
                    }))
        }
        return false
    }
}
