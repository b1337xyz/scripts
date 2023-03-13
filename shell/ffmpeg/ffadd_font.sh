#!/bin/sh
for i in "$@";do
    mimetype=$(file -Lbi -- "$i")
    case "$mimetype" in
        *truetype-font|*opentype)
            font="$i"
            mime="$mimetype" ;;
        video/*) video="$i"  ;;
    esac
done
out="new_${vid##*/}"
ffmpeg -nostdin -v 24 -stats  \
    -i "$vid" -attach "$font" \
    -map_metadata 0 -map 0    \
    -metadata:s mimetype="$mime" -c copy "$out"
