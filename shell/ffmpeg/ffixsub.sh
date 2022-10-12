#!/bin/sh

[ -f "$1" ] || exit 1

# -map a:m:language:jpn   \
# -metadata:s:a:0 language=jpn    \

output=new_${1##*/}
ffmpeg -i "$1" -map_metadata 0 -map 0:v \
    -map a:m:language:jpn   \
    -map s:m:language:por?  \
    -map s:m:language:eng?  \
    -map 0:t?               \
    -map -v:m:mimetype:image/jpeg?  \
    -disposition:s:0 default        \
    -c copy "$output"
