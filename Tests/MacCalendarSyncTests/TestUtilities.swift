import EventKit
import Foundation

@testable import MacCalendarSyncLib

// MARK: - Test Data Creation Utilities

func makeCalendar(eventStore: EKEventStore, title: String) throws -> EKCalendar {
    let calendar = EKCalendar(for: .event, eventStore: eventStore)
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

// MARK: - Test Setup Helpers

struct TestCalendarSetup {
    let eventStore: EKEventStore
    let calendar1: MyCalendar
    let calendar2: MyCalendar
    let startDate: Date
    let endDate: Date
    let formatter: ISO8601DateFormatter

    init(
        events1: [(title: String, from: String, to: String, notes: String?)] = [],
        events2: [(title: String, from: String, to: String, notes: String?)] = [],
        calendar1Name: String = "Test Calendar 1",
        calendar2Name: String = "Test Calendar 2"
    ) async throws {
        self.formatter = ISO8601DateFormatter()
        self.eventStore = MockEventStore()

        let ekCalendar1 = try makeCalendar(eventStore: eventStore, title: calendar1Name)
        let ekCalendar2 = try makeCalendar(eventStore: eventStore, title: calendar2Name)

        for event in events1 {
            try makeEvent(
                eventStore: eventStore,
                title: event.title,
                calendar: ekCalendar1,
                from: event.from,
                to: event.to,
                notes: event.notes
            )
        }

        for event in events2 {
            try makeEvent(
                eventStore: eventStore,
                title: event.title,
                calendar: ekCalendar2,
                from: event.from,
                to: event.to,
                notes: event.notes
            )
        }

        self.calendar1 = MyCalendar(eventStore: eventStore, title: ekCalendar1.title)
        self.calendar2 = MyCalendar(eventStore: eventStore, title: ekCalendar2.title)
        self.startDate = formatter.date(from: "2023-01-01T00:00:00Z")!
        self.endDate = formatter.date(from: "2023-01-01T23:23:59Z")!
    }
}

// MARK: - Mock Event Store

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
