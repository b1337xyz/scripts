#!/usr/bin/env bash

while read -r stream;do
    if [[ "$stream" =~ ': Audio' ]];then
        [[ "$stream" =~ ^[0-9]*\(eng\): ]] && continue
    fi

    if [[ "$stream" =~ ^[0-9]*\( ]];then
        stream="${stream%(*}"
    else
        stream="${stream%:*}"
    fi

    map+=" -map 0:$stream" 
done < <(ffmpeg -i "$1" 2>&1 | grep -oP '(?<=Stream #0:).*' | cut -d':' -f-2)
map="${map:1}"

[ -z "$map" ] && exit 1

out="new_${1##*/}"
ffmpeg -hide_banner -i "$1" -map_chapters 0 -map_metadata 0 $map -c copy "${2:-$out}" || { rm -i "$out"; exit 1; }
