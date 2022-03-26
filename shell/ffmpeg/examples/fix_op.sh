#!/bin/sh

ffmpeg -hide_banner -i "$1" -map_metadata 0 -map 0 -map -0:2 -map -0:5 -map -0:4 \
    -metadata:s:s:1 language=por -c:s:0 copy -c:a copy -c:v copy new_"$1"
