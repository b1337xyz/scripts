#!/usr/bin/env bash

out=new_"${1##*/}"
if ! ffmpeg -nostdin -hide_banner -i "$1" -map_metadata 0 -map 0:v \
    -map 0:a:m:language:jpn         \
    -map 0:s -map 0:t?              \
    -map -v:m:mimetype:image/jpeg?  \
    -c copy "$out"
then
    rm "$out"
    exit 1
fi

