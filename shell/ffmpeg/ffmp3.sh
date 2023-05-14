#!/bin/sh
output="${1%.*}.mp3"
ffmpeg -hide_banner -v 16 -stats -i "$1" -map 0:a -vn \
    -c:a libmp3lame -b:a 320k -ac 2 "$output"
