#!/bin/sh

out=./new_${1##*/}
out=${out%.*}.mp4
ffmpeg -nostdin -hide_banner -i "$1" \
    -filter_complex 'color=black,format=rgb24[c];[c][0]scale2ref[c][i];[c][i]overlay=format=auto:shortest=1,setsar=1' \
    -an -crf 16 -c:v libx264 \
    -preset fast -pix_fmt yuv420p "$out"
