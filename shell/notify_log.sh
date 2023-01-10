#!/bin/sh
logfile=~/.cache/notifications
dbus-monitor "interface='org.freedesktop.Notifications'"|
    grep --line-buffered -oP '(?<=string ").+(?="$)'    |
    grep --line-buffered -vP '^(:\d+\.\d+|urgency|sender-pid|notify-send|\s*)$' |
    xargs -I{} printf '--- %s ---\n%s\n' "$(date)" '{}' >> "$logfile"

