#!/bin/sh
set -e

THRESHOLD=88
TARGET=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

[ -e "$TARGET" ] || sleep 15
[ -w "$TARGET" ] || { echo "cannot write to file: $TARGET"; exit 1; }

while sleep 300; do
    capacity=$(cat /sys/class/power_supply/BAT?/capacity)
    value=$(cat "$TARGET")
    if   [ "$value" = 0 ] && [ "${capacity:-0}" -ge "$THRESHOLD" ]; then
        echo 1 > "$TARGET"
        echo "INFO: conservation mode enabled at ${capacity}%"
    elif [ "$value" = 1 ] && [ "${capacity:-0}" -lt "$THRESHOLD" ]; then
        echo 0 > "$TARGET"
        echo "INFO: conservation mode disabled at ${capacity}%"
    fi
done
