#!/usr/bin/env bash

bar_height=0
border=2
IFS='x' read -r scr_width scr_height < <(
    xrandr -q | grep ' connected' | grep -oP '\d+x\d+'
)
#IFS='x' read -r scr_width scr_height < <(
#    i3-msg -t get_tree | jq -r '.["rect"] | "\(.["width"])x\(.["height"])"')

case "$1" in
    top)
        width=$scr_width height=$((scr_height / 2 - bar_height))
        x=0 y=$bar_height ;;
    top-left)
        width=$((scr_width / 2)) height=$((scr_height / 2 - bar_height))
        x=0 y=$bar_height  ;;
    right)
        width=$((scr_width / 2)) height=$((scr_height - bar_height - 1))
        x=$((scr_width / 2 - border)) y=$bar_height ;;
    left)
        width=$((scr_width / 2)) height=$((scr_height - bar_height - 1))
        x=$border y=$bar_height ;;
    bottom)
        width=$scr_width height=$((scr_height / 2))
        x=0 y=$((scr_height / 2)) ;;

esac
i3-msg resize set "$width $height"
i3-msg move position "$x $y"
