#!/bin/sh

set -e

# -map 0:a:m:language:jpn \
output=new_"${1##*/}"
ffmpeg -i "$1" -i "$2" -map_metadata 0 -map 0:v \
    -map 0:a \
    -map 1:s \
    -map 0:s:m:language:eng? \
    -map 0:t? -map 1:t? \
    -map -v:m:mimetype:image/jpeg?  \
    -metadata:s:a:0 language=jpn        \
    -metadata:s:s:0 language=por        \
    -metadata:s:s:0 title='Portuguese'  \
    -disposition:s:s 0 \
    -disposition:s:0 default \
    -c copy "$output"
