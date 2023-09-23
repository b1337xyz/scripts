#!/bin/sh
pkill -x dunst; sleep .15
msg="$(date)\n$(uname -r) $(uname -o)" 
notify-send -u low "Low urgency" "$msg"
notify-send -i ~/Pictures/random/anime/lainux.jpg -u normal "Normal urgency" "$msg"
notify-send -u critical "Critical urgency" "$msg"
