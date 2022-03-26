#!/bin/sh

# -map a:m:language:jpn   \
# -metadata:s:a:0 language=jpn    \
output=new_${1##*/}
if ! ffmpeg -i "$1" -map_metadata 0 -map 0:v \
    -map 0:a \
    -map s:m:title:Brazilian   \
    -map s:m:language:eng?  \
    -map 0:t?               \
    -map -v:m:mimetype:image/jpeg?  \
    -disposition:s:0 default        \
    -c copy "$output"
then
    rm -vf "$output"
    exit 1
fi
