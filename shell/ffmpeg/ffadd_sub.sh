#!/bin/sh

set -e

for i in "$@";do
    mimetype=$(file -Lbi "$i")
    case "$mimetype" in
        video/*) vid="$i" ;;
        text/*) sub="$i" ;;
    esac
done

output=new_"${vid##*/}"
ffmpeg -i "$vid" -i "$sub" -map_metadata 0 -map 0:v -map 0:a \
    -map 1 -map 0:s:m:language:eng? -map 0:t?   \
    -map -v:m:mimetype:image/jpeg?              \
    -metadata:s:s:0 language=por        \
    -metadata:s:s:0 title='Portuguese'  \
    -disposition:s:0 default            \
    -c copy "$output" || exit 1

# rm -i "$vid" "$sub"
