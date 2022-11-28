#!/bin/sh
out="${1##*/}"
out="${out}.gif"

ffmpeg -nostdin -i "$1" \
    -filter_complex 'split[a][b];[a]palettegen[p];[b][p]paletteuse' "$out"
