#!/bin/sh
out="${1##*/}"
out="${out%.*}.mp4"

# -max_muxing_queue_size 1024 : fix "too many packets buffered for output"
ffmpeg -nostdin -v 24 -stats -i "$1" \
    -c:v h264 -crf 21 -profile:v baseline \
    -pix_fmt yuv420p -preset fast \
    -tune zerolatency -threads 0 "$out"
