#!/bin/sh

killall i3bar
i3bar --bar_id=bar-0 --socket="$I3SOCK" >/dev/null 2>&1 &
