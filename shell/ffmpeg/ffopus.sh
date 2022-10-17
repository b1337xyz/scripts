#!/bin/sh
# https://github.com/slhck/ffmpeg-normalize/issues/98
set -e

ff() {
    inp="$1"
    out=opus_${1##*/}
    shift
    ffmpeg -nostdin -v 24 -stats -i "$inp"-map_metadata 0 -map 0:v \
        -map 0:a:m:language:jpn \
        -map 0:s -map 0:t?   \
        -c copy -c:a libopus "$@" "$out"
}

if ffmpeg -nostdin -i "$1" 2>&1 | grep -q ' 5.1(side),'
then
    ff "$1" -af "channelmap=channel_layout=5.1"
else
    ff "$1"
fi
