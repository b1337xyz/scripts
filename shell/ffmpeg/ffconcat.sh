#!/bin/sh

tmpfile=$(mktemp tmp.XXXXXXXX)
trap 'rm "$tmpfile"' EXIT INT HUP
for i in "$@";do
    file -Lbi -- "$i" 2>/dev/null |
        grep -q '^image' && echo "file '$i'"
done > "$tmpfile"
tac "$tmpfile" >> "$tmpfile"

ffmpeg -nostdin -v 24 -stats -y \
    -r 12 -f concat -safe 0     \
    -i "$tmpfile" -c:v libx264  \
    -crf 16 -preset fast \
    -pix_fmt yuv420p output.mp4

mpv output.mp4 --loop-file=inf
