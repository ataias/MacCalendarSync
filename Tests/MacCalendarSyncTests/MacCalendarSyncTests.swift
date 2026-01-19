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

@Suite("IgnoreInviteeTests")
struct IgnoreInviteeTests {
    let setup: TestCalendarSetup
    let attendeeTracker: TestAttendeeTracker

    init() async throws {
        // Calendar 1 (target): has some [EXTERNAL] events from previous syncs
        let events1 = [
            ("Regular Event", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z", nil as String?),
            ("[EXTERNAL] Team Meeting", "2023-01-01T14:00:00Z", "2023-01-01T15:00:00Z", nil),
        ]

        // Calendar 2 (source): has events with various attendees
        let events2 = [
            ("Team Meeting", "2023-01-01T14:00:00Z", "2023-01-01T15:00:00Z", nil as String?),
            ("Project Sync", "2023-01-01T16:00:00Z", "2023-01-01T17:00:00Z", nil),
            ("Special Calendar Event", "2023-01-01T09:00:00Z", "2023-01-01T10:00:00Z", nil),
        ]

        self.setup = try await TestCalendarSetup(events1: events1, events2: events2)

        // Set up attendees for source events
        self.attendeeTracker = TestAttendeeTracker()
        attendeeTracker.setAttendees(
            ["alice@company.com", "bob@company.com"],
            forEventTitle: "Team Meeting",
            startDate: "2023-01-01T14:00:00Z"
        )
        attendeeTracker.setAttendees(
            ["alice@company.com"],
            forEventTitle: "Project Sync",
            startDate: "2023-01-01T16:00:00Z"
        )
        attendeeTracker.setAttendees(
            ["alice@company.com", "group@company.com"],
            forEventTitle: "Special Calendar Event",
            startDate: "2023-01-01T09:00:00Z"
        )
    }

    @Test func ignoresEventsWithSpecifiedInvitee() async throws {
        let diff = setup.calendar1.diff(
            setup.calendar2,
            start: setup.startDate,
            end: setup.endDate,
            redact: false,
            ignoreInvitees: ["group@company.com"],
            getAttendeeEmails: attendeeTracker.getAttendees
        )

        // "Special Calendar Event" should be ignored because it has the ignored invitee
        // "Team Meeting" is already synced (synced list contains target calendar events)
        // "Project Sync" should be added
        #expect(diff.synced.count == 1)
        #expect(diff.synced[0].title == "[EXTERNAL] Team Meeting")

        #expect(diff.add.count == 1)
        #expect(diff.add[0].title == "[EXTERNAL] Project Sync")

        #expect(diff.remove.count == 0)
    }

    @Test func ignoresEventsWithCaseInsensitiveEmail() async throws {
        let diff = setup.calendar1.diff(
            setup.calendar2,
            start: setup.startDate,
            end: setup.endDate,
            redact: false,
            ignoreInvitees: ["GROUP@COMPANY.COM"],
            getAttendeeEmails: attendeeTracker.getAttendees
        )

        // Should still ignore the event even with different case
        let addedTitles = diff.add.map { $0.title }
        #expect(!addedTitles.contains("[EXTERNAL] Special Calendar Event"))
    }

    @Test func allowsAllEventsWhenNoIgnoreInvitees() async throws {
        let diff = setup.calendar1.diff(
            setup.calendar2,
            start: setup.startDate,
            end: setup.endDate,
            redact: false,
            ignoreInvitees: [],
            getAttendeeEmails: attendeeTracker.getAttendees
        )

        // All non-synced source events should be added
        #expect(diff.add.count == 2)
        let addedTitles = diff.add.map { $0.title }.sorted()
        #expect(addedTitles.contains("[EXTERNAL] Project Sync"))
        #expect(addedTitles.contains("[EXTERNAL] Special Calendar Event"))
    }

    @Test func ignoresMultipleInvitees() async throws {
        let diff = setup.calendar1.diff(
            setup.calendar2,
            start: setup.startDate,
            end: setup.endDate,
            redact: false,
            ignoreInvitees: ["group@company.com", "alice@company.com"],
            getAttendeeEmails: attendeeTracker.getAttendees
        )

        // All source events have alice@company.com, so nothing should be added
        #expect(diff.add.count == 0)

        // Team Meeting is synced but has ignored invitee, so synced should be empty
        #expect(diff.synced.count == 0)

        // The [EXTERNAL] Team Meeting should be removed since its source is now ignored
        #expect(diff.remove.count == 1)
        #expect(diff.remove[0].title == "[EXTERNAL] Team Meeting")
    }
}

@Suite("IgnoreInviteeTests - External Deletion")
struct IgnoreInviteeExternalDeletionTests {
    @Test func deletesExternalCopyWhenIgnoreInviteeEnabled() async throws {
        // Scenario: An event was previously synced (without ignore-invitee)
        // Now we run with ignore-invitee and the [EXTERNAL] copy should be deleted

        // Calendar 1 (target): has [EXTERNAL] copy from previous sync
        let events1 = [
            ("[EXTERNAL] Special Calendar Event", "2023-01-01T09:00:00Z", "2023-01-01T10:00:00Z", nil as String?),
        ]

        // Calendar 2 (source): has the original event with ignored invitee
        let events2 = [
            ("Special Calendar Event", "2023-01-01T09:00:00Z", "2023-01-01T10:00:00Z", nil as String?),
        ]

        let setup = try await TestCalendarSetup(events1: events1, events2: events2)

        let attendeeTracker = TestAttendeeTracker()
        attendeeTracker.setAttendees(
            ["user@company.com", "group@company.com"],
            forEventTitle: "Special Calendar Event",
            startDate: "2023-01-01T09:00:00Z"
        )

        // First, verify without ignore-invitee the events are synced
        let diffWithoutIgnore = setup.calendar1.diff(
            setup.calendar2,
            start: setup.startDate,
            end: setup.endDate,
            redact: false,
            ignoreInvitees: [],
            getAttendeeEmails: attendeeTracker.getAttendees
        )

        #expect(diffWithoutIgnore.synced.count == 1)
        #expect(diffWithoutIgnore.remove.count == 0)
        #expect(diffWithoutIgnore.add.count == 0)

        // Now with ignore-invitee enabled, the [EXTERNAL] copy should be deleted
        let diffWithIgnore = setup.calendar1.diff(
            setup.calendar2,
            start: setup.startDate,
            end: setup.endDate,
            redact: false,
            ignoreInvitees: ["group@company.com"],
            getAttendeeEmails: attendeeTracker.getAttendees
        )

        // Source event is ignored, so no synced events
        #expect(diffWithIgnore.synced.count == 0)

        // Nothing to add since source is ignored
        #expect(diffWithIgnore.add.count == 0)

        // The [EXTERNAL] copy should be marked for removal
        try #require(diffWithIgnore.remove.count == 1)
        #expect(diffWithIgnore.remove[0].title == "[EXTERNAL] Special Calendar Event")
    }

    @Test func deletesMultipleExternalCopiesWhenIgnoreInviteeEnabled() async throws {
        // Calendar 1 (target): has multiple [EXTERNAL] copies from previous syncs
        let events1 = [
            ("[EXTERNAL] Event A", "2023-01-01T09:00:00Z", "2023-01-01T10:00:00Z", nil as String?),
            ("[EXTERNAL] Event B", "2023-01-01T11:00:00Z", "2023-01-01T12:00:00Z", nil),
            ("[EXTERNAL] Event C", "2023-01-01T13:00:00Z", "2023-01-01T14:00:00Z", nil),
        ]

        // Calendar 2 (source): original events
        let events2 = [
            ("Event A", "2023-01-01T09:00:00Z", "2023-01-01T10:00:00Z", nil as String?),
            ("Event B", "2023-01-01T11:00:00Z", "2023-01-01T12:00:00Z", nil),
            ("Event C", "2023-01-01T13:00:00Z", "2023-01-01T14:00:00Z", nil),
        ]

        let setup = try await TestCalendarSetup(events1: events1, events2: events2)

        let attendeeTracker = TestAttendeeTracker()
        // Event A and B have the ignored invitee, Event C does not
        attendeeTracker.setAttendees(
            ["user@company.com", "shared-calendar@company.com"],
            forEventTitle: "Event A",
            startDate: "2023-01-01T09:00:00Z"
        )
        attendeeTracker.setAttendees(
            ["other@company.com", "shared-calendar@company.com"],
            forEventTitle: "Event B",
            startDate: "2023-01-01T11:00:00Z"
        )
        attendeeTracker.setAttendees(
            ["user@company.com"],
            forEventTitle: "Event C",
            startDate: "2023-01-01T13:00:00Z"
        )

        let diff = setup.calendar1.diff(
            setup.calendar2,
            start: setup.startDate,
            end: setup.endDate,
            redact: false,
            ignoreInvitees: ["shared-calendar@company.com"],
            getAttendeeEmails: attendeeTracker.getAttendees
        )

        // Event C should remain synced (synced list contains target calendar events)
        #expect(diff.synced.count == 1)
        #expect(diff.synced[0].title == "[EXTERNAL] Event C")

        // Nothing to add
        #expect(diff.add.count == 0)

        // Event A and B [EXTERNAL] copies should be removed
        #expect(diff.remove.count == 2)
        let removedTitles = diff.remove.map { $0.title }.sorted()
        #expect(removedTitles.contains("[EXTERNAL] Event A"))
        #expect(removedTitles.contains("[EXTERNAL] Event B"))
    }
}
