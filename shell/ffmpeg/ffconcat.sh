#!/bin/sh
set -e

tmpfile=$(mktemp tmp.XXXXXXXX)
trap 'rm "$tmpfile"' EXIT
for i in "$@";do
    file -Lbi -- "$i" 2>/dev/null |
        grep -q '^image' && echo "file '$i'"
done > "$tmpfile"
printf 'tac? [y/N] '; read -r ask
# shellcheck disable=SC2094
[ "$ask" = y ] && tac "$tmpfile" >> "$tmpfile"

ffmpeg -nostdin -v 24 -stats -y \
    -r 10 -f concat -safe 0     \
    -i "$tmpfile" -c:v libx264  \
    -crf 5 -preset fast -tune animation \
    output.mp4

# mpv output.mp4 --loop-file=inf
