#!/bin/sh
output="${1%.*}.mp3"
ffmpeg -hide_banner -v 16 -i "$1" -vn \
    -c:a libmp3lame -q:a 1 -f mp3 -joint_stereo 1 "$output"
