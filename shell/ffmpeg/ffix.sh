#!/bin/sh
set -e

audio="0:a"
if ffmpeg -nostdin -i "$1" 2>&1 | grep -q 'Stream #0:.(jpn): Audio:' 
then
    audio="0:a:m:language:jpn"
fi

# -map s:m:title:Brazil? \
output=new_${1##*/}
ffmpeg -nostdin -v 24 -stats -i "$1" \
    -map_metadata 0 -map 0:v -map "$audio"   \
    -map s:m:language:por? \
    -map s:m:language:eng? \
    -map 0:t?              \
    -map -v:m:mimetype:image/jpeg?  \
    -disposition:s:0 default \
    -c copy "$output"
