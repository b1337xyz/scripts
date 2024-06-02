#!/usr/bin/env bash
set -eo pipefail
position=$(slurp -b 00000000 -p && sleep .44)
color=$(grim -g "$position" -t png - | magick - -format '%[pixel:p{0,0}]' txt:- | awk 'END{print $3}')

if [ -n "$color" ];then
    wl-copy -n <<< "$color"
    magick -size 40x40 xc:"$color" /tmp/.color.png
    notify-send -i /tmp/.color.png "$color" "copied to clipboard"
fi
