#!/bin/sh
for i in $(seq 3 -1 1);do printf "%s..." "$i" ; sleep .7 ;done
[ -z "$1" ] && out="picture_$(date +%d%m%Y%H%M).png" || out="$1"
notify-send -i camera-photo "$out"
printf '\nOutput: %s\n' "$out"

ffmpeg -nostdin -hide_banner -v 16 \
    -f v4l2 -i /dev/video0 -vframes 1 "$out"

sxiv "$out"
