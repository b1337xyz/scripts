#!/usr/bin/env bash

out=${1##*/}
out=${out%.*}.webm
ffmpeg -hide_banner -t 13 -i "$1" -an -c:v libvpx \
    -b:v 1M "$out"
