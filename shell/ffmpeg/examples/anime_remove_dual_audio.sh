#!/bin/sh

out=new_"$1"
if ffmpeg -i "$1" -map_metadata 0 -map 0:v -map a:m:language:jpn -map 0:s -map 0:t? -c copy "$out" ;then
    rm -v "$1"
else
    rm -v "$out"
    exit 1
fi
