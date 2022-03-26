#!/usr/bin/env bash

fname="${1##*/}"
fname="${1%.*}"

while read -r stream;do
    [[ "$stream" =~  ': Subtitle' ]] || continue
    [[ "$stream" =~ ^[0-9]*\(por\): ]] || continue
    if [[ "$stream" =~ ': ass' ]];then
        ext=ass
    else
        ext=srt
    fi
    stream="${stream%(*}"
    out=${fname}.$ext
    c=1
    while [ -f "$out" ];do
        out="$fname ($c).$ext"
        (( c += 1 ))
    done
    printf '%s > %s\n' "$1" "$out"

    # disable shellcheck=SC2086
    ffmpeg -nostdin -hide_banner -v 16 \
        -i "$1" -map 0:${stream} -c copy "$out" || { rm -f "$out"; exit 1; }

done < <(ffmpeg -i "$1" 2>&1 | grep -oP '(?<=Stream #0:).*')


