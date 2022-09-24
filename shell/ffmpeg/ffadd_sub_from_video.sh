#!/bin/sh

set -e

output=new_"${1##*/}"
ffmpeg -i "$1" -i "$2" -map_metadata 0 -map 0:v \
    -map 0:a:m:language:jpn \
    -map 1:s \
    -map 1:t? \
    -map -v:m:mimetype:image/jpeg?  \
    -metadata:s:s:0 language=por        \
    -metadata:s:s:0 title='Portuguese'  \
    -disposition:s:s 0 \
    -disposition:s:0 default \
    -c copy "$output"
