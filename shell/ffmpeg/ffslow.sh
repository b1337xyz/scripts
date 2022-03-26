#!/usr/bin/env bash
output="${1%.*}.mp4"
c=1
while [ -a "$output" ];do
    output="${c}_${1%.*}.mp4"
    c=$((c+1))
done
printf '%s \e[1;33m~>\e[m %s\n' "$1" "$output"

ffmpeg -nostdin -hide_banner -v 16 -t 12 -i "$1"  \
    -c:v h264 -crf 23 -profile:v baseline -pix_fmt yuv420p \
    -filter_complex "[0:v]setpts=1.75*PTS[v];[0:a]atempo=0.6[a]" \
    -map "[v]" -map "[a]" "$output"

[ $? -ne 0 ] && { rm -v "$output"; exit 1; }
exit 0
