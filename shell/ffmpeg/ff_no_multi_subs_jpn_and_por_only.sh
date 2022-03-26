#!/usr/bin/env bash
# shellcheck disable=SC2086

while read -r stream;do

    if [[ "$stream" =~ ^[0-9]*\(...\): ]];then
        if [[ "$stream" =~  ': Subtitle' ]];then
            [[ "$stream" =~ ^[0-9]*\((por|eng)\): ]] || continue
        elif [[ "$stream" =~ ': Audio' ]];then
            [[ "$stream" =~ ^[0-9]*\((jpn|por)\): ]] || continue
        fi
    fi

    if [[ "$stream" =~ ^[0-9]*\( ]];then
        idx=${stream%%:*} idx=${idx%(*}
    else
        idx=${stream%%:*}
    fi

    map+=" -map 0:$idx" 
done < <(ffmpeg -i "$1" 2>&1 | grep -oP '(?<=Stream #0:).*' | grep -v '\(png\|jpg\|jpeg\)')

map="${map:1}"
[ -z "$map" ] && exit 1

out="new_${1##*/}"

printf '%s > %s\n' "$1" "$out"
ffmpeg -nostdin -hide_banner \
    -i "$1" $map -c copy "$out" || { rm -f "$out"; exit 1; }

exit 0
