#!/usr/bin/env bash

case "${2##*.}" in
    ttf)
        ffmpeg -v 16 -i "$1" -attach "$2" \
            -map_metadata 0 -map 0 \
            -metadata:s mimetype=application/x-truetype-font -c copy "$3"
    ;;
    otf)
        ffmpeg -v 16 -i "$1" -attach "$2" \
            -map_metadata 0 -map 0 \
            -metadata:s mimetype=application/vnd.ms-opentype -c copy "$3"
    ;;
esac


