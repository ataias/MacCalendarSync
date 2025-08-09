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
                "\n\n[BASE_HASH]52e0244b3943f027009ee88ce8345d100f1d282e1a153f931e1d02c30688c051"
            ),
        ]

        let events2 = [
            (
                "[EXTERNAL]", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z",
                "\n\n[BASE_HASH]52e0244b3943f027009ee88ce8345d100f1d282e1a153f931e1d02c30688c051"
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
        print(event.hash())
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
                == "[BASE_HASH]52e0244b3943f027009ee88ce8345d100f1d282e1a153f931e1d02c30688c051")
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
                == "[BASE_HASH]156105adbf6c574ff1b89ccad689faf1475ecaf6dbd0d304c0ef0289a25a7311")
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
                == "[BASE_HASH]31dc3df45d0beccff67ca1e4ba39eb04b906e1756bcf2aac9e543c5929ae0d59")
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

        // For redacted tests, we need to create temp events to get the correct hashes
        let tempEventStore = MockEventStore()
        let formatter = ISO8601DateFormatter()

        let tempEvent1 = EKEvent(eventStore: tempEventStore)
        tempEvent1.title = "Meeting with Client"
        tempEvent1.startDate = formatter.date(from: "2023-01-01T10:00:00Z")!
        tempEvent1.endDate = formatter.date(from: "2023-01-01T11:00:00Z")!

        let tempEvent2 = EKEvent(eventStore: tempEventStore)
        tempEvent2.title = "Team Standup"
        tempEvent2.startDate = formatter.date(from: "2023-01-01T14:00:00Z")!
        tempEvent2.endDate = formatter.date(from: "2023-01-01T15:00:00Z")!

        let events2 = [
            (
                "[EXTERNAL]", "2023-01-01T10:00:00Z", "2023-01-01T11:00:00Z",
                "\n\n[BASE_HASH]\(tempEvent1.hash())"
            ),
            (
                "[EXTERNAL]", "2023-01-01T14:00:00Z", "2023-01-01T15:00:00Z",
                "\n\n[BASE_HASH]\(tempEvent2.hash())"
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

        let formatter = ISO8601DateFormatter()
        let tempEventStore = MockEventStore()

        let tempEvent1 = EKEvent(eventStore: tempEventStore)
        tempEvent1.title = "Meeting with Client"
        tempEvent1.startDate = formatter.date(from: "2023-01-01T10:00:00Z")!
        tempEvent1.endDate = formatter.date(from: "2023-01-01T11:00:00Z")!

        let tempEvent2 = EKEvent(eventStore: tempEventStore)
        tempEvent2.title = "Team Standup"
        tempEvent2.startDate = formatter.date(from: "2023-01-01T14:00:00Z")!
        tempEvent2.endDate = formatter.date(from: "2023-01-01T15:00:00Z")!

        let syncedEvents = diff.synced.sorted { $0.startDate < $1.startDate }

        #expect(syncedEvents[0].title == "[EXTERNAL]")
        #expect(
            syncedEvents[0].notes?.trimmingCharacters(in: .whitespacesAndNewlines) == "[BASE_HASH]\(tempEvent1.hash())")

        #expect(syncedEvents[1].title == "[EXTERNAL]")
        #expect(
            syncedEvents[1].notes?.trimmingCharacters(in: .whitespacesAndNewlines) == "[BASE_HASH]\(tempEvent2.hash())")
    }
}
