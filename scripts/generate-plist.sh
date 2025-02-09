#!/bin/zsh

# Both calendars will be kept in since
LEFT=$1
RIGHT=$2
EXTRA=${@:3} # example "--days 28 --dry-run"
PROGRAM=$(which mac-calendar-sync)

cat <<-_EOT_
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>br.com.ataias.my-calendar-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>-c</string>
        <string>date; ${PROGRAM} --verbose --target-calendar-name "${LEFT}" --source-calendar-name "${RIGHT}" ${EXTRA}; ${PROGRAM} --verbose --target-calendar-name "${RIGHT}" --source-calendar-name "${LEFT}" ${EXTRA}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/mac-calendar-sync-stderr.txt</string>
    <key>StandardOutPath</key>
    <string>/tmp/mac-calendar-sync-stdout.txt</string>
    <key>StartInterval</key>
    <integer>300</integer>
</dict>
</plist>
_EOT_
