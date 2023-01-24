#!/bin/sh
res=$(xrandr -q |grep -P ' \d+x\d+[\t ]+\d+\.\d+\*\+' | awk '{print $1}' | head -1)
# wallpaper=$(grep -oP '(?<=").*(?="$)' ~/.cache/xwallpaper)
scrot -o -m /tmp/scrlock.png 
convert /tmp/scrlock.png -resize "${res}!"  -blur 0x3 RGB:- |
    i3lock -u -e --raw 1366x768:rgb --image /dev/stdin

[ "$1" = "off" ] && xset dpms force off

exit 0
