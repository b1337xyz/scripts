#!/bin/sh

output=new_"${1##*/}"
if ! ffmpeg -i "$1" -i "$2" -map_metadata 0 -map 0:v -map 0:a \
    -map 1:s:m:language:por \
    -map 0:s:m:language:eng?        \
    -map -v:m:mimetype:image/jpeg?  \
    -map 0:t? -map 1:t?             \
    -metadata:s:s:0 language=por        \
    -metadata:s:s:0 title='Portuguese'  \
    -disposition:s:0 default            \
    -c copy "$output"
then
    rm "$output"
    exit 1
fi

