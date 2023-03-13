#!/bin/sh
output=/tmp/palette_"$1"
convert "$1" +dither -colors 8 -unique-colors -filter box -resize 2800% "$output"
sxiv -qps f "$output" 2>/dev/null
