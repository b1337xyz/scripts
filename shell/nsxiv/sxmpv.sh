#!/usr/bin/env bash
ptr='.*\.(mp4|mkv|webm|avi|m4v|mov)'
DIR=~/.cache/thumbnails/sxmpv
find . -maxdepth 1 -regextype posix-extended -iregex "$ptr" -type f | sort -V | while read -r i
do
    img="${DIR}/${i##*/}.jpg"
    if ! [ -f "$img" ];then
        mkdir -p "${img%/*}"
        ffmpegthumbnailer -s 0 -i "$i" -o "$img" 2>/dev/null
    fi
    printf '%s\n' "$img"
done | sxiv -qito | sed 's/.*\//\.\//; s/\.jpg$//'
