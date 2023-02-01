#!/bin/sh
set -ex

for i in "$@";do
    mimetype=$(file -Lbi -- "$i")
    case "$mimetype" in
        video/*) vid="$i" ;;
        text/*)  sub="$i" ;;
    esac
done
[ -f "$sub" ] || sub=${vid%.*}.ass
[ -f "$sub" ] || sub=${vid%.*}.srt
[ -f "$sub" ] || { printf 'subtitle not found\n'; exit 1; }
echo "vid: $vid"
echo "sub: $sub"

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
