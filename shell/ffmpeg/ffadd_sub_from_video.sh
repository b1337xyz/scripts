#!/bin/sh

set -e

if ffmpeg -i "$1" 2>&1 | grep -q 'Stream #0:.(jpn): Audio:' 
then
    audio="0:a:m:language:jpn"
else
    audio="0:a"
fi

output=new_"${1##*/}"
ffmpeg -nostdin -v 24 -stats -i "$1" -i "$2" -map_metadata 0 -map 0:v \
    -map "$audio" \
    -map 1:s -map 1:t? \
    -map -v:m:mimetype:image/jpeg?  \
    -metadata:s:s:0 language=por        \
    -metadata:s:s:0 title='Portuguese'  \
    -disposition:s:s 0 \
    -disposition:s:0 default \
    -c copy "$output"
