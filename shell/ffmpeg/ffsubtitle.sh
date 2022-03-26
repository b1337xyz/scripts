#!/usr/bin/env bash
output="${1%.*}.mp4"
c=1
while [ -a "$output" ];do
    output="${c}_${1%.*}.mp4"
    c=$((c+1))
done
printf '%s \e[1;33m~>\e[m %s\n' "$1" "$output"

ffmpeg -hide_banner -v 16 -i "$1" \
    -c:v h264 -crf 20 -profile:v baseline -pix_fmt yuv420p -preset ultrafast -tune zerolatency \
    -vf "subtitles=$2" "$output"

[ $? -ne 0 ] && { rm -v "$output"; exit 1; }
exit 0
