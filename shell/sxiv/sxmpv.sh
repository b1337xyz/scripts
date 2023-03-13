#!/usr/bin/env bash
ptr='.*\.(mp4|mkv|webm|avi)'
tmpdir=/tmp/sxiv
mkdir -p "$tmpdir"
find . -maxdepth 1 -regextype posix-extended \
    -iregex "$ptr" -type f | sort -V | while read -r i
do
    img="${tmpdir}/${i##*/}.jpg"
    test -f "$img" || ffmpegthumbnailer -s 300 -i "$i" -o "$img" 2>/dev/null
    printf '%s\n' "$img"
done | sxiv -qito | sed 's/.*\//\.\//; s/\.jpg$//'
