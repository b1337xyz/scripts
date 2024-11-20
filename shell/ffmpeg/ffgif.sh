#!/usr/bin/env bash
set -e
ext=${1##*.} ext=${ext,,}
out="${1##*/}" out="${out}.gif"

# ffmpeg -nostdin -i "$1" \
#     -filter_complex 'scale=848:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse' "$out"

mkdir -p /tmp/2gif
trap 'rm -r /tmp/2gif' EXIT
if [[ "$ext" =~ mp4|mov|mkv|m4v|avi|mov|flv|mpg|webm ]];then
    ffmpeg -nostdin -hide_banner -i "$1" -r 10 /tmp/2gif/out%05d.png
    magick -delay 1x10 /tmp/2gif/*.png -fuzz 1% +dither -coalesce -layers OptimizeTransparency +map "$out"
else
    convert "$1" GIF87:"${1%%.*}.gif"
fi
