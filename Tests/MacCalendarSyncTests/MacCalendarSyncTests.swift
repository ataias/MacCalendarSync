import EventKit
import Testing

@testable import MacCalendarSyncLib

@Suite("CalendarSyncTests - Non Redacted")
struct CalendarSyncNonRedactedTests {
    let setup: TestCalendarSetup

    init() async throws {
        let events1 = [
            ("Event 1", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("Some Event in Calendar 1", "2023-01-01T08:00:00Z", "2023-01-01T09:00:00Z", nil),
            ("[EXTERNAL] Unknown 1", "2023-01-01T08:00:00Z", "2023-01-01T09:00:00Z", nil),
        ]

        let events2 = [
            ("[EXTERNAL] Event 1", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("[EXTERNAL] Unknown 2", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil),
            ("Some Event in Calendar 2", "2023-01-01T09:00:00Z", "2023-01-01T10:00:00Z", nil),
        ]

        self.setup = try await TestCalendarSetup(events1: events1, events2: events2)
    }

    @Test func identifiesNonRedactedSyncedEventsFromCalendar1To2() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "Event 1")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T11:00:00Z")!)
    }

    @Test func identifiesNonRedactedSyncedEventsFromCalendar2To1() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "[EXTERNAL] Event 1")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T11:00:00Z")!)
    }

    @Test func identifiesNonRedactedAddEventsFromCalendar1To2() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        #expect(event.title == "[EXTERNAL] Some Event in Calendar 2")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T09:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
    }

    @Test func identifiesNonRedactedAddEventsFromCalendar2To1() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        #expect(event.title == "[EXTERNAL] Some Event in Calendar 1")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T08:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T09:00:00Z")!)
    }

    @Test func identifiesNonRedactedRemoveEventsFromCalendar1To2() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.remove.count == 1)
        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 1")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T08:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T09:00:00Z")!)
    }

    @Test func identifiesNonRedactedRemoveEventsFromCalendar2To1() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.remove.count == 1)
        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 2")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T11:00:00Z")!)
    }
}

@Suite("CalendarSyncTests - Redacted")
struct CalendarSyncRedactedTests {
    let setup: TestCalendarSetup

    init() async throws {
        let events1 = [
            ("Event 1", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("Some Event in Calendar 1", "2023-01-01T08:00:00Z", "2023-01-01T09:00:00Z", nil),
            ("[EXTERNAL] Unknown 1", "2023-01-01T08:00:00Z", "2023-01-01T09:00:00Z", nil),
            (
                "[EXTERNAL]", "2023-01-01T13:00:00Z", "2023-01-01T14:00:00Z",
                createBaseHashNotes(for: "Event 1", from: "2023-01-01T10:00:00Z", to: "2023-01-01T11:00:00Z")
            ),
        ]

        let events2 = [
            (
                "[EXTERNAL]", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z",
                createBaseHashNotes(for: "Event 1", from: "2023-01-01T10:00:00Z", to: "2023-01-01T11:00:00Z")
            ),
            ("[EXTERNAL] Unknown 2", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("Some Event in Calendar 2", "2023-01-01T09:00:00Z", "2023-01-01T10:00:00Z", nil),
        ]

        self.setup = try await TestCalendarSetup(events1: events1, events2: events2)
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar1To2() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "Event 1")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T11:00:00Z")!)
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar2To1() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.synced.count == 1)
        let event = diff.synced[0]
        #expect(event.title == "[EXTERNAL]")
        #expect(
            event.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]\(computeEventHash(title: "Event 1", from: "2023-01-01T10:00:00Z", to: "2023-01-01T11:00:00Z"))"
        )
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T11:00:00Z")!)
    }

    @Test func identifiesRedactedAddEventsFromCalendar1To2() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        #expect(event.title == "[EXTERNAL]")
        #expect(
            event.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]\(computeEventHash(title: "Some Event in Calendar 2", from: "2023-01-01T09:00:00Z", to: "2023-01-01T10:00:00Z"))"
        )
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T09:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
    }

    @Test func identifiesRedactedAddEventsFromCalendar2To1() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.add.count == 1)
        let event = diff.add[0]
        #expect(event.title == "[EXTERNAL]")
        #expect(
            event.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]\(computeEventHash(title: "Some Event in Calendar 1", from: "2023-01-01T08:00:00Z", to: "2023-01-01T09:00:00Z"))"
        )
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T08:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T09:00:00Z")!)
    }

    @Test func identifiesRedactedRemoveEventsFromCalendar1To2() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.remove.count == 1)
        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 1")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T08:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T09:00:00Z")!)
    }

    @Test func identifiesRedactedRemoveEventsFromCalendar2To1() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.remove.count == 1)
        let event = diff.remove[0]
        #expect(event.title == "[EXTERNAL] Unknown 2")
        #expect(event.notes == nil)
        #expect(event.startDate == setup.formatter.date(from: "2023-01-01T10:00:00Z")!)
        #expect(event.endDate == setup.formatter.date(from: "2023-01-01T11:00:00Z")!)
    }
}

@Suite("ForwardedEventTests - FW: Prefix")
struct ForwardedEventTests {
    let setup: TestCalendarSetup

    init() async throws {
        let events1 = [
            ("FW: Meeting with Client", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("FW: Team Standup", "2023-01-01T14:00:00Z", "2023-01-01T15:00:00Z", nil),
        ]

        let events2 = [
            ("Meeting with Client", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("[EXTERNAL] Team Standup", "2023-01-01T14:00:00Z", "2023-01-01T15:00:00Z", nil),
        ]

        self.setup = try await TestCalendarSetup(events1: events1, events2: events2)
    }

    @Test func identifiesSyncedEventsWithFWPrefix() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.synced.count == 2)
        let syncedTitles = diff.synced.map { $0.title }.sorted()
        #expect(syncedTitles.contains("FW: Meeting with Client"))
        #expect(syncedTitles.contains("FW: Team Standup"))
    }

    @Test func identifiesSyncedEventsWithoutFWPrefix() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.synced.count == 2)
        let syncedTitles = diff.synced.map { $0.title }.sorted()
        #expect(syncedTitles.contains("Meeting with Client"))
        #expect(syncedTitles.contains("[EXTERNAL] Team Standup"))
    }
}

@Suite("ForwardedEventTests - FW: Prefix Redacted")
struct ForwardedEventRedactedTests {
    let setup: TestCalendarSetup

    init() async throws {
        let events1 = [
            ("FW: Meeting with Client", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("FW: Team Standup", "2023-01-01T14:00:00Z", "2023-01-01T15:00:00Z", nil),
        ]

        let events2 = [
            (
                "[EXTERNAL]", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z",
                createBaseHashNotes(
                    for: "Meeting with Client", from: "2023-01-01T10:00:00Z", to: "2023-01-01T11:00:00Z")
            ),
            (
                "[EXTERNAL]", "2023-01-01T14:00:00Z", "2023-01-01T15:00:00Z",
                createBaseHashNotes(for: "Team Standup", from: "2023-01-01T14:00:00Z", to: "2023-01-01T15:00:00Z")
            ),
        ]

        self.setup = try await TestCalendarSetup(events1: events1, events2: events2)
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar1To2WithFWPrefix() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.synced.count == 2)
        let syncedTitles = diff.synced.map { $0.title }.sorted()
        #expect(syncedTitles.contains("FW: Meeting with Client"))
        #expect(syncedTitles.contains("FW: Team Standup"))
    }

    @Test func identifiesRedactedSyncedEventsFromCalendar2To1WithFWPrefix() async throws {
        let diff = setup.calendar2.diff(setup.calendar1, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.synced.count == 2)

        let syncedEvents = diff.synced.sorted { $0.startDate < $1.startDate }

        #expect(syncedEvents[0].title == "[EXTERNAL]")
        #expect(
            syncedEvents[0].notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]\(computeEventHash(title: "Meeting with Client", from: "2023-01-01T10:00:00Z", to: "2023-01-01T11:00:00Z"))"
        )

        #expect(syncedEvents[1].title == "[EXTERNAL]")
        #expect(
            syncedEvents[1].notes?.trimmingCharacters(in: .whitespacesAndNewlines)
                == "[BASE_HASH]\(computeEventHash(title: "Team Standup", from: "2023-01-01T14:00:00Z", to: "2023-01-01T15:00:00Z"))"
        )
    }
}

@Suite("AllDayEventTests")
struct AllDayEventTests {
    let setup: TestCalendarSetupWithAllDay

    init() async throws {
        let events1 = [
            ("All-Day Event", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil as String?, true),
            ("Timed Event", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil, false),
        ]

        let events2 = [
            ("[EXTERNAL] All-Day Event", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil as String?, true),
            ("Different Event", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil, false),
        ]

        self.setup = try await TestCalendarSetupWithAllDay(events1: events1, events2: events2)
    }

    @Test func preservesAllDayStatusWhenCopying() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.add.count == 1)
        let addedEvent = diff.add[0]
        #expect(addedEvent.title == "[EXTERNAL] Different Event")
        #expect(addedEvent.isAllDay == false)
    }

    @Test func identifiesSyncedAllDayEvents() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: false)
        try #require(diff.synced.count == 1)
        let syncedEvent = diff.synced[0]
        #expect(syncedEvent.title == "All-Day Event")
        #expect(syncedEvent.isAllDay == true)
    }

    @Test func distinguishesAllDayFromTimedEventsWithSameDates() async throws {
        // Create two events with the same start and end dates but different isAllDay status
        let events1 = [
            ("Event A", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil as String?, true)
        ]
        let events2 = [
            ("Event A", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil as String?, false)
        ]

        let setup = try await TestCalendarSetupWithAllDay(events1: events1, events2: events2)
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: false)

        // These should NOT be synced because one is all-day and one is not
        #expect(diff.synced.count == 0)
        #expect(diff.add.count == 1)
    }
}

@Suite("AllDayEventTests - Redacted")
struct AllDayEventRedactedTests {
    let setup: TestCalendarSetupWithAllDay

    init() async throws {
        let events1 = [
            ("All-Day Event", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil as String?, true)
        ]

        let events2 = [
            (
                "[EXTERNAL]", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z",
                createBaseHashNotesWithAllDay(for: "All-Day Event", from: "2023-01-01T00:00:00Z", to: "2023-01-02T00:00:00Z", isAllDay: true),
                true
            )
        ]

        self.setup = try await TestCalendarSetupWithAllDay(events1: events1, events2: events2)
    }

    @Test func identifiesRedactedSyncedAllDayEvents() async throws {
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: true)
        try #require(diff.synced.count == 1)
        let syncedEvent = diff.synced[0]
        #expect(syncedEvent.title == "All-Day Event")
        #expect(syncedEvent.isAllDay == true)
    }

    @Test func distinguishesRedactedAllDayFromTimedEventsWithSameDates() async throws {
        // Create an all-day event in calendar 1 and a non-all-day event in calendar 2 with the same dates
        // Calendar 2 has a redacted event that looks like it might match, but it's not all-day
        let events1 = [
            ("All-Day Event", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil as String?, true)
        ]
        let events2 = [
            // This is a NON-all-day event that happens to have the same dates as the all-day event in calendar 1
            ("Some Event", "2023-01-01T00:00:00Z", "2023-01-02T00:00:00Z", nil as String?, false)
        ]

        let setup = try await TestCalendarSetupWithAllDay(events1: events1, events2: events2)
        let diff = setup.calendar1.diff(setup.calendar2, start: setup.startDate, end: setup.endDate, redact: true)

        // These should NOT be synced because one is all-day and one is not, even in redacted mode
        #expect(diff.synced.count == 0)
        #expect(diff.add.count == 1)
    }
}
