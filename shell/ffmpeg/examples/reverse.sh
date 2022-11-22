#!/bin/sh

ffmpeg -nostdin -hide_banner -i "$1" -crf 0 \
    -filter_complex '[0:v:0]reverse[r];[0:v:0][r]concat=n=2:v=1' output.mp4
