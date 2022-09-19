#!/usr/bin/env bash

ffmpeg -i "$1" 2>&1 | grep Subtitle:
read -r -p 'Stream: ' stream

#shellcheck disable=SC2086
ffmpeg -i "$1" -map_metadata 0 -map 0 -metadata:s:$stream language=por -c copy new_"${1##*/}"


