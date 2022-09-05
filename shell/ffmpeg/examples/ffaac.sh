#!/bin/sh

ext=${1##*.}
out=${2:-out_aac.${ext}}

ffmpeg -i "$1" -map_metadata 0 -map 0 \
    -c copy -c:a aac -b:a 128k -threads 8 "$out"

