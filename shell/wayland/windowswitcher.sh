#!/bin/sh
window=$(swaymsg -t get_tree | jq -r '.nodes[].nodes[].nodes[].nodes[] | select(.focused | not) |
    "\(.name) :\(.pid)"' | rofi -dmenu -i)

[ -z "$window" ] && exit 0
swaymsg "[pid=${window##*:}]" focus
