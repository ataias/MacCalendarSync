# MacCalendarSync

MacCalendarSync is a command line tool that allows you to sync events from one calendar to the other via the macOS Calendar app. Local or external calendars that are connected your Calendar app can be used as source and target calendars for synchronization. Events are compared for equality based on title, location, start and end dates. Events can also be redacted, and in this case comparison involves hashing the previously mentioned properties. To facilitate differentiating between copied and non-copied events, the prefix "[EXTERNAL]" is added to the title of the copied event. That prefix is ignored for the purposes of comparing two events for equality.

To run it:

```
swift run -- MacCalendarSync --verbose --target-calendar-name "Target Calendar" --source-calendar-name "Source Calendar" --start-date "2025-02-10 00:00:00" --end-date "2025-02-21 23:23:59" --dry-run
```

## Install

```sh
make
make install
```

The above will install the program to `~/.local/bin/MacCalendarSync`. If that's not in your path, you can either customize your path or install it to another location:

```sh
# Note this needs sudo because it install in a root directory
PREFIX=/usr/local/bin sudo make -e install
```

## Pending Work

- [Allow for generation fo shell completion](https://swiftpackageindex.com/apple/swift-argument-parser/1.5.0/documentation/argumentparser/installingcompletionscripts)
- [Allow for an easy way of installing schedules and enabling them using launchd](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html)
  - Intention is to allow running the program on a schedule to keep a set of calendars synchronized

## Known Bugs

- When a copied redacted event is modified (start/endDate), it is not identified for deletion; need to add a test for that
  - If the original event for the copied redacted event is modified, behavior is as expected and the redacted copy is deleted and then a new entry is added with the updated version; that works even if there were changes in the start/endDate of the redacted event in the mean time
