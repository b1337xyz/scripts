#!/bin/sh

WALL=~/Pictures/wallpapers
find -L "$WALL" -type d -printf '%h\0' | xargs -r0 basename -a | sort -u | dmenu -c -l 10 -i | xargs -rI '<>' find "$WALL" -type d -name '<>' -exec find -L '{}' -name '*.jpg' \; | shuf | sxiv -fbiq -S 15 -s h >/dev/null 2>&1
