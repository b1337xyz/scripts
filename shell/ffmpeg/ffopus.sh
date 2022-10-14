#!/bin/sh
# https://github.com/slhck/ffmpeg-normalize/issues/98

alias ff='ffmpeg -nostdin -v 24 -stats'

out=opus_${1##*/}
if ffmpeg -nostdin -i "$1" 2>&1 | grep -q ' 5.1(side),'
then
    ff "$1" -map_metadata 0 -map 0:v  \
        -map 0:a:m:language:jpn \
        -map 0:s -map 0:t?   \
        -c copy -c:a libopus \
        -af "channelmap=channel_layout=5.1" "$out" 
else
    ff -i "$1" -map_metadata 0 -map 0:v  \
        -map 0:a:m:language:jpn \
        -map 0:s -map 0:t? \
        -c copy -c:a libopus "$out"
fi
