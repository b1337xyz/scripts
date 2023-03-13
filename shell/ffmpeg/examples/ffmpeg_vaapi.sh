#!/bin/sh

out="new_${1##*/}"
ffmpeg -hide_banner -vaapi_device /dev/dri/renderD128 -i "$1" \
    -vf 'format=p010,hwupload' \
    -c:a copy -c:v hevc_vaapi -crf 29 \
    -preset fast -tune zerolatency -threads 8 "$out" || { rm -f "$out"; exit 1; }
