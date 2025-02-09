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

The above will install the program to `~/.local/bin/mac-calendar-sync`. If that's not in your path, you can either customize your path or install it to another location:

```sh
# Note this needs sudo because it install in a root directory
PREFIX=/usr/local/bin sudo make -e install
```

### Auto Completions
For autocompletions, you can generate them for your shell with the following commands:

```sh
mac-calendar-sync --generate-completion-script bash
mac-calendar-sync --generate-completion-script zsh
mac-calendar-sync --generate-completion-script fish
```

If you have [oh-my-zsh](https://ohmyz.sh/) installed, you already have a directory of automatically loading completion scripts — `.oh-my-zsh/completions`. Copy your new completion script to that directory.

```sh
$ MacCalendarSync --generate-completion-script zsh > ~/.oh-my-zsh/completions/_example
```

If you have fish installed, copy the completion script to any path listed in the environment variable `$fish_completion_path`. For example, a typical location is `~/.config/fish/completions/your_script.fish`. You can also do that easily with one of our make commands:

```sh
make install-completions-fish
```

If none of the cases above works for you, please research on how to enable completions for your shell. A few more options can be seen [here](https://swiftpackageindex.com/apple/swift-argument-parser/1.5.0/documentation/argumentparser/installingcompletionscripts).

## Pending Work

- [Allow for an easy way of installing schedules and enabling them using launchd](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html)
  - Intention is to allow running the program on a schedule to keep a set of calendars synchronized

## Known Bugs

- When a copied redacted event is modified (start/endDate), it is not identified for deletion; need to add a test for that
  - If the original event for the copied redacted event is modified, behavior is as expected and the redacted copy is deleted and then a new entry is added with the updated version; that works even if there were changes in the start/endDate of the redacted event in the mean time
