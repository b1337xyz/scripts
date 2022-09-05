#!/bin/sh

out=hvec_"$1"
ffmpeg -hide_banner -i "$1" -c:v libx265 -crf 26 -preset faster "$out"


