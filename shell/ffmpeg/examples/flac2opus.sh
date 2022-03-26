#!/bin/sh

set -e

out=opus
[ -d "$out" ] || mkdir -v "$out"

find . -iname '*.flac' | while read -r i;do
    [ -f "$i" ] || continue
    d=${i%/*}
    d=$out/${d##*/}
    [ -d "$d" ] || mkdir -vp "$d"
    f=${i##*/}
    f=$d/${f%.*}.opus
    [ -f "$f" ] && continue
    if ! ffmpeg -hide_banner -nostdin -i "$i" -map_metadata 0 -map 0:a \
        -c:a libopus -compression_level 10 -b:a 96k "$f"
    then
        rm -vf "$f"
        exit 1
    fi
done
