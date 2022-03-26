#!/usr/bin/env bash

map_streams=
while read -r i;do
    map_streams="${map_streams} -map 0:$i"
done < <(ffmpeg -i "$1" 2>&1 | grep -oP '(?<=Stream #0:)[0-9]+(?=: Attachment)')

[ -z "$map_streams" ] && exit 1

ffmpeg -i "$1" -i "$2" -map_metadata 1 -map 1 $map_streams -c copy "new_${2##*/}.${2##*.}"
