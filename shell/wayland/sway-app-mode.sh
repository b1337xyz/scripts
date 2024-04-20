#!/bin/sh
# > ~/.config/sway/config
# mode passthrough {
#         bindsym $mod+0 mode default
# }

swaymsg -t subscribe -m '[ "window" ]' | while read -r _;do
    swaymsg -r -t get_tree | jq '.. | select(.type?) | select(.focused==true).name'
done |
    while read -r line; do
        case "$line" in
            *TigerVNC*)
                swaymsg mode passthrough ;;
            *)
                swaymsg mode default ;;
        esac
        # echo "$line"
    done
