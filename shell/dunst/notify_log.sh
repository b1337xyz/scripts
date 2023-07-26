#!/bin/sh
logfile=~/.cache/notifications
# grep --line-buffered -oP '.*(?=string)|(?<=string).*' |
dbus-monitor "interface='org.freedesktop.Notifications'"  |
    grep --line-buffered -oP '(?<=string ").+(?="$)'

    # grep --line-buffered -vP '^(:\d+\.\d+|urgency|sender-pid|notify-send|\s+)$' |
    # xargs -rI{} printf '--- %s ---\n%s\n' "$(date)" '{}' # >> "$logfile"
