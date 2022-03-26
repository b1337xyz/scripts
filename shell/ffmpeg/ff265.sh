#!/bin/sh

out=hvec_"$1"
if ! ffmpeg -hide_banner -i "$1" -c:v libx265 -crf 26 -preset faster "$out";then
    rm -f "$out"
    exit 1
fi

