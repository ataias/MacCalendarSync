import CommonCrypto
import EventKit
import Foundation

let SYNC_PREFIX = "[EXTERNAL]"

public let INPUT_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"

public struct MyCalendar {
    public let title: String

    internal let calendar: EKCalendar
    internal let eventStore: EKEventStore

    public init(
        eventStore: EKEventStore,
        title: String
    ) {
        guard
            let calendar = eventStore.calendars(for: .event).filter({
                $0.title == title
            }).first
        else {
            print(#function, "Calendar with title \"\(title)\" not found")
            fatalError()
        }
        guard calendar.allowsContentModifications else {
            print(
                #function,
                "Calendar \(calendar) does not allow content modifications")
            fatalError()
        }

        self.calendar = calendar
        self.title = title
        self.eventStore = eventStore
    }

    public func diff(
        _ other: MyCalendar,
        start: Date,
        end: Date,
        redact: Bool
    ) -> CalendarDiff {
        let myEvents = self.getEvents(start: start, end: end)
        let otherEvents = other.getEvents(start: start, end: end)

        let synced = myEvents.filter { event in
            return otherEvents.contains { otherEvent in
                return areEventsEqual(event, otherEvent, rhsRedacted: redact)
            }
        }

        let add =
            otherEvents
            .filter {
                !$0.title.hasPrefix(SYNC_PREFIX)
            }
            .filter { event in
                let isContained = synced.contains { otherEvent in
                    return areEventsEqual(
                        event, otherEvent, rhsRedacted: redact)
                }

                return !isContained
            }.map { otherCalendarEvent in
                let event = EKEvent(eventStore: eventStore)
                event.title = [SYNC_PREFIX, otherCalendarEvent.title]
                    .compactMap({ $0 })
                    .joined(separator: " ")
                event.location = otherCalendarEvent.location
                event.startDate = otherCalendarEvent.startDate
                event.endDate = otherCalendarEvent.endDate
                var notes = otherCalendarEvent.notes ?? ""
                if redact {
                    event.title = SYNC_PREFIX
                    event.location = nil
                    notes.append("\n\n[BASE_HASH]\(otherCalendarEvent.hash())")
                }
                event.notes = notes
                event.calendar = self.calendar

                return event

            }

        let remove =
            myEvents
            .filter {
                $0.title.hasPrefix(SYNC_PREFIX)
            }
            .filter { event in
                let isContained = synced.contains { otherEvent in
                    return areEventsEqual(
                        event, otherEvent, rhsRedacted: redact)
                }

                return !isContained
            }

        return CalendarDiff(synced: synced, add: add, remove: remove)
    }

    public func getEvents(start: Date, end: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: start, end: end, calendars: [self.calendar])
        let events = eventStore.events(matching: predicate)
        return events
    }
}

private func areEventsEqual(
    _ lhs: EKEvent, _ rhs: EKEvent, rhsRedacted: Bool = false
) -> Bool {
    if rhsRedacted {
        if rhs.title == SYNC_PREFIX && lhs.title != SYNC_PREFIX {
            let rhsNotes = rhs.notes ?? ""
            let rhsHash = rhsNotes.split(separator: "[BASE_HASH]").last ?? ""
            return lhs.hash() == rhsHash
        }
        if lhs.title == SYNC_PREFIX && rhs.title != SYNC_PREFIX {
            let lhsNotes = lhs.notes ?? ""
            let lhsHash = lhsNotes.split(separator: "[BASE_HASH]").last ?? ""
            return lhsHash == rhs.hash()
        }

    }

    let title = lhs.title.replacingOccurrences(
        of: "\(SYNC_PREFIX) ", with: ""
    ).replacingOccurrences(of: "FW: ", with: "")
    let location = lhs.location
    let startDate = lhs.startDate
    let endDate = lhs.endDate

    let rhsTitle = rhs.title.replacingOccurrences(
        of: "\(SYNC_PREFIX) ", with: ""
    ).replacingOccurrences(of: "FW: ", with: "")
    let rhsLocation = rhs.location
    let rhsStartDate = rhs.startDate
    let rhsEndDate = rhs.endDate

    return title == rhsTitle && location == rhsLocation
        && startDate == rhsStartDate && endDate == rhsEndDate

}

extension EKEvent {
    public func hash() -> String {
        let formatter = ISO8601DateFormatter()
        let title: String = self.title.replacingOccurrences(
            of: "\(SYNC_PREFIX) ", with: ""
        ).replacingOccurrences(of: "FW: ", with: "")
        let location: String = self.location ?? ""
        let startDate: String = formatter.string(from: self.startDate)
        let endDate: String = formatter.string(from: self.endDate)

        return "\(title),\(location),\(startDate),\(endDate)".sha256()
    }
}

public struct CalendarDiff {
    /// Events were already synced and needs no changes
    public let synced: [EKEvent]
    /// Events should be added to the current calendar
    public let add: [EKEvent]
    /// Events should be removed to the current calendar
    public let remove: [EKEvent]
}

/// A calendar event with properties related to EKEvent. It can be easily initialized without a store.
/// Properties that are not relevant were not added
public struct CalendarEvent: CustomStringConvertible {

    let id: String
    /// The title for the calendar item.
    let title: String
    let calendar: String
    let startDate: Date
    let endDate: Date
    let organizer: Participant
    let attendees: [Participant]
    let status: EKEventStatus
    let availability: EKEventAvailability

    public init(event: EKEvent) {
        self.id = event.calendarItemExternalIdentifier!
        self.title = event.title
        self.calendar = event.calendar.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.organizer = Participant(event.organizer)
        self.attendees = event.attendees?.compactMap(Participant.init) ?? []
        self.status = event.status
        self.availability = event.availability
    }

    public var description: String {
        return """
            ------------------------------------------
            id: \(id)
            title: \(title)
            time: [\(startDate), \(endDate)]
            status: \(status)
            organizer: \(organizer.email)
            attendees:
            \t\(attendees.map({$0.email}).joined(separator: "\n\t"))
            """
    }

    public var compactDescription: String {
        let shortId = String(id.prefix(8))
        let startStr = DateFormatter.shortDateTime.string(from: startDate)
        let endStr = DateFormatter.shortDateTime.string(from: endDate)
        let parts = organizer.email.split(separator: "@")
        let organizerDomain: String =
            if organizer.email.contains("@") {
                parts.count >= 2 ? String(parts.last!) : "unknown"
            } else {
                organizer.email.isEmpty ? "unknown" : organizer.email
            }

        return "  [\(shortId)] \(title) | \(startStr) - \(endStr) | \(organizerDomain)"
    }

}
public struct CalendarPeriod {
    let calendars: [EKCalendar]
    let eventStore: EKEventStore
    let start: Date
    let end: Date

    public init(
        eventStore: EKEventStore, startDate: Date, endDate: Date,
        filter: ((EKCalendar) -> Bool)
    ) {
        self.eventStore = eventStore
        let calendars = eventStore.calendars(for: .event).filter(filter)
        self.calendars = calendars

        self.start = startDate
        self.end = endDate
    }

    public func getEvents() -> [CalendarEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        return events.map { ekEvent in
            return CalendarEvent(event: ekEvent)
        }
    }
}

public struct Participant {
    let email: String

    init(_ participant: EKParticipant?) {
        guard let participant else {
            self.email = "unknown@unknown.com"
            return
        }
        self.email = participant.url.absoluteString.replacingOccurrences(
            of: "mailto:", with: "")
    }
}

extension EKEventStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .confirmed:
            return "confirmed"
        case .tentative:
            return "tentative"
        case .canceled:
            return "canceled"
        @unknown default:
            return "unknown"
        }
    }
}

extension EKEventAvailability: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .free:
            return "free"
        case .busy:
            return "busy"
        case .notSupported:
            return "not supported"
        case .tentative:
            return "tentative"
        case .unavailable:
            return "unavailable"
        @unknown default:
            return "unknown"
        }
    }
}

extension Data {
    public func sha256() -> String {
        return hexStringFromData(input: digest(input: self as NSData))
    }

    private func digest(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }
}

extension String {
    public func sha256() -> String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }
}

extension DateFormatter {
    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
