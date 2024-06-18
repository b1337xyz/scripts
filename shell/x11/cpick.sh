#!/usr/bin/env bash
color=$(sxcs --hex -o | cut -f2)
if [ -n "$color" ];then
    xclip -rmlastnl -sel c <<< "$color"
    magick -size 40x40 xc:"$color" /tmp/.color.png
    notify-send -i /tmp/.color.png "$color" "copied to clipboard"
fi

