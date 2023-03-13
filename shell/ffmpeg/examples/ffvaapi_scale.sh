#!/bin/sh

out="new_${1##*/}"
ffmpeg -hide_banner -vaapi_device /dev/dri/renderD128 -i "$1" \
    -vf 'format=p010,hwupload,deinterlace_vaapi=rate=field:auto=1,scale_vaapi=w=1280:h=720' \
    -c:a copy -c:s copy -c:v hevc_vaapi -crf 28 \
    -preset ultrafast -tune zerolatency "$out" || { rm -f "$out"; exit 1; }
