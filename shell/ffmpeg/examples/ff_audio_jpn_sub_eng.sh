#!/bin/sh

output=new_${1##*/}
if ! ffmpeg -i "$1" -map_metadata 0 -map 0:v \
    -map a:m:language:jpn \
    -map s:m:language:eng \
    -disposition:s:0 default \
    -map 0:t? -c copy "$output"
then
    rm -vf "$output"
    exit 1
fi

exit 0
