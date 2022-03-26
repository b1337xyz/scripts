#!/bin/sh

mode=$(cat << EOF | dmenu -c -i -l 6 | cut -d':' -f1
1: HDMI1 left of eDP1
2: HDMI1 right of eDP1
3: HDMI1 only
4: eDP1 only
5: HDMI1 same as eDP1
EOF
)
[ -z "$mode" ] && exit 1

case "$mode" in
    1) xrandr --output eDP1 --primary --auto --output HDMI1 --brightness 0.6 --left-of eDP1 --auto ;;
    2) xrandr --output eDP1 --primary --auto --output HDMI1 --brightness 0.6 --right-of eDP1 --auto ;;
    3) xrandr --output eDP1 --off --output HDMI1 --brightness 0.6 --primary --auto ;;
    4) xrandr --output eDP1 --primary --auto --output HDMI1 --off;;
    5) xrandr --output HDMI1 --same-as eDP1 ;;
    *) exit 1 ;;
esac

pgrep -x i3 && i3-msg restart 
sleep 1 && sh ~/.cache/xwallpaper
