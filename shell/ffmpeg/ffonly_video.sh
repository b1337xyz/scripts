#!/bin/sh

out=new_"$1"
if ! ffmpeg -i "$1" -map 0:v -c copy "$out" ;then
    rm -f "$out"
    exit 1
fi
