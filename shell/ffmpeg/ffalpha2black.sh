#!/bin/sh

out=./new_${1##*/}
out=${out%.*}.mp4
filter="color=black,format=rgb24[c];[c][0]scale2ref[c][i];[c][i]overlay=format=auto:shortest=1,setsar=1[outv]; [outv]pad='ceil(iw/2)*2:ceil(ih/2)*2'"
ffmpeg -nostdin -hide_banner -y -i "$1" \
    -an -crf 16 -c:v libx264 \
    -filter_complex "$filter"  \
    -preset fast -pix_fmt yuv420p "$out"
