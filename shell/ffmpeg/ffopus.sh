#!/usr/bin/env bash
# https://github.com/slhck/ffmpeg-normalize/issues/98
# -af "channelmap=channel_layout=5.1"

case "$1" in
    5.1)
        out=opus_${2##*/}
        ffmpeg -nostdin -i "$2"     \
            -map_metadata 0 -map 0  \
            -c copy -c:a libopus    \
            -af "channelmap=channel_layout=5.1" "$out" 
    ;;
    *)
        out=opus_${1##*/}
        ffmpeg -nostdin -i "$1"     \
            -map_metadata 0 -map 0 \
            -c copy -c:a libopus "$out"
    ;;
esac || { rm -vf "$out"; exit 1; }

exit 0
