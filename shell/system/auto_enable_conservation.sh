#!/bin/sh
set -e

THRESHOLD=90
TARGET=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

[ -w "$TARGET" ] || exit 1

while sleep 60; do
    capacity=$(cat /sys/class/power_supply/BAT?/capacity)
    value=$(cat "$TARGET")
    if   [ "$value" -eq 0 ] && [ "${capacity:-0}" -ge "$THRESHOLD" ]; then
        echo 1 > "$TARGET"
    elif [ "$value" -eq 1 ] && [ "${capacity:-0}" -lt "$THRESHOLD" ]; then
        echo 0 > "$TARGET"
    fi
done
