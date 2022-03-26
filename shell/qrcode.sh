#!/usr/bin/env bash
# scan the qrcode of the selected area by scrot

output=$(mktemp -u /tmp/tmp.XXXXXXXX.png)
sleep 1 ; scrot -s -q 100 "$output"
zbarimg "$output"
[ -f "$output" ] && rm "$output"
