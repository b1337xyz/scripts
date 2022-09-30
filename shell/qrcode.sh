#!/bin/sh
output=$(mktemp -u /tmp/tmp.XXXXXXXX.png)
sleep 1 ; scrot -s -q 100 "$output"
zbarimg "$output"
[ -f "$output" ] && rm "$output"
