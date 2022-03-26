#!/usr/bin/env bash

while read -r stream;do
    if [[ "$stream" =~ ': Subtitle' ]];then
        if [[ "$stream" =~ ^[0-9]*\(...\): ]];then
            [[ "$stream" =~ ^[0-9]*\((por|eng)\): ]] || continue
        fi
    fi

    if [[ "$stream" =~ ^[0-9]*\( ]];then
        stream="${stream%(*}"
    else
        stream="${stream%:*}"
    fi

    map+=" -map 0:$stream" 
done < <(ffmpeg -i "$1" 2>&1 | grep -oP '(?<=Stream #0:).*' | grep -v '\(jpeg\|png\|jpg\)' | cut -d':' -f-2)
map="${map:1}"

[ -z "$map" ] && exit 1

out="new_${1##*/}"
printf '%s -> %s\n' "$1" "$out"

# shellcheck disable=SC2086
ffmpeg -hide_banner -i "$1" -map_metadata 0 $map -c copy "$out" || { rm -i "$out"; exit 1; }
