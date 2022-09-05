#!/bin/sh
set -e

tmpfile=$(mktemp tmp.XXXXXXXX)
end() { rm "$tmpfile"; }
trap end EXIT
for i in "$@";do
    file -Lbi "$i" 2>/dev/null | grep -q '^image' && echo "file '$i'"
done > "$tmpfile"

tac "$tmpfile" >> "$tmpfile"

ffmpeg -hide_banner -y -r 12 -f concat -safe 0 -i "$tmpfile" -pix_fmt yuv420p output.mp4
mpv output.mp4 --loop-file=inf
