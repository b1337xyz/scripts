#!/bin/sh
set -e

for i in "$@";do
    mimetype=$(file -Lbi -- "$i")
    case "$mimetype" in
        video/*) vid="$i" ;;
        text/*)  sub="$i" ;;
    esac
done
[ -f "$sub" ] || sub=${vid%.*}.ass
[ -f "$sub" ] || sub=${vid%.*}.srt
[ -f "$sub" ] || { printf 'usage: %s <video> <subtitle>\n' "${0##*/}"; exit 1; }
printf 'vid: \033[1;32m%s\033[m\nsub: \033[1;32m%s\033[m\n' "$vid" "$sub"

if ffmpeg -i "$vid" 2>&1 | grep -q 'Stream #0:.(jpn): Audio:' 
then
    audio="0:a:m:language:jpn"
else
    audio="0:a"
fi

output=new_"${vid##*/}"
ffmpeg -nostdin -v 24 -stats -i "$vid" -i "$sub" \
    -map_metadata 0 -map 0:v -map "$audio" -map 1 \
    -map -v:m:mimetype:image/jpeg? \
    -metadata:s:s:0 language=por \
    -metadata:s:s:0 title='Portuguese' \
    -disposition:s:0 default \
    -c copy "$output"

rm -i "$vid" "$sub"
