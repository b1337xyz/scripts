#!/bin/sh
set -e

tmpfile=$(mktemp tmp.XXXXXXXX)
trap 'rm "$tmpfile"' EXIT INT HUP
for i in "$@";do
    file -Lbi -- "$i" 2>/dev/null |
        grep -q '^image' && echo "file '$i'"
done > "$tmpfile"
tac "$tmpfile" >> "$tmpfile"

ffmpeg -nostdin -v 24 -stats -y \
    -r 10 -f concat -safe 0     \
    -i "$tmpfile" -c:v libx264  \
    -crf 5 -preset fast -tune animation \
    output.mp4

# mpv output.mp4 --loop-file=inf
