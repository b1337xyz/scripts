#!/bin/sh
output="${1%.*}.gif"
i=2
while [ -s "$output" ];do
    output="${1%.*}_${i}.gif"
    i=$((i+1))
    echo "$output"
done
printf '%s -> %s\n' "$1" "$output"

if ! ffmpeg -hide_banner -nostdin -v 16 -i "$1" \
    -filter_complex 'split[a][b];[a]palettegen[p];[b][p]paletteuse' "$output"
then
    rm -vf "$output" 2>/dev/null; exit 1
fi
exit 0
