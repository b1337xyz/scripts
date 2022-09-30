#!/bin/sh

for f in /sys/devices/virtual/dmi/id/*
do
    printf '%s: ' "${f##*/}"
    echo -n "$f === "
    cat "$f" 2>/dev/null || printf '\e[1;31mUnavailable\e[m\n'
done

exit 0
