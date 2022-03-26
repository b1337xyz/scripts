#!/bin/sh
output="${1%.*}.mp4"
i=1
while [ -f "$output" ];do
    output="${1%.*}_$i.mp4"
    i=$((i+1))
done
printf '%s \e[1;34m~\e[1;31m>\e[m %s\n' "$1" "$output"

# -max_muxing_queue_size 1024 : fix "too many packets buffered for output"
if ! ffmpeg -nostdin -hide_banner -v 16 -i "$1" \
    -c:v h264 -crf 21 -profile:v baseline -pix_fmt yuv420p \
    -preset ultrafast -tune zerolatency -threads 0 "$output"
then
    rm -vf "$output"; exit 1
fi
exit 0
