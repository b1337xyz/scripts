#!/usr/bin/env bash

f=${1##*/}
out=${f%.*}.webm
ffmpeg -hide_banner -t 13 -i "$1" -an -c:v libvpx \
    -b:v 1M "$out"
