#!/usr/bin/env bash

printf '%s \e[1;32m>\e[m %s \e[1;32m>\e[m %s\n' "$1" "$2" "$3"

if ffmpeg -hide_banner -v 16 -i "$1" -i "$2" \
    -map 0 -map 1 -map_metadata 0 -map_chapters 1 -map -1:v -map -1:a -c copy "$3"
then
    ffmpeg -i "$3" 2>&1 | grep Stream | grep -v Attach
    printf '%s Attachments\n' "$(ffmpeg -i "$3" 2>&1 | grep -c Attach)"
    rm -i "$1" "$2"
fi


