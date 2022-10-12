#!/bin/sh
set -e

# https://github.com/slhck/ffmpeg-normalize/issues/98
# -af "channelmap=channel_layout=5.1"

out=opus_${1##*/}
if ffmpeg -i "$1" 2>&1 | grep -q ' 5.1(side),'
then
    ffmpeg -nostdin -v 24 -stats -i "$1"     \
        -map_metadata 0 -map 0:v  \
        -map 0:a:m:language:jpn \
        -map 0:s -map 0:t? \
        -c copy -c:a libopus    \
        -af "channelmap=channel_layout=5.1" "$out" 
else
    out=opus_${1##*/}
    ffmpeg -nostdin -v 24 -stats -i "$1"     \
        -map_metadata 0 -map 0:v  \
        -map 0:a:m:language:jpn \
        -map 0:s -map 0:t? \
        -c copy -c:a libopus "$out"
fi
