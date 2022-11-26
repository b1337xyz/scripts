#!/bin/sh
if xrandr | grep -q 'HDMI1 connected';then
    xrandr --output eDP1 --primary --auto --output HDMI1 --left-of eDP1 --auto
    pgrep -x i3 && i3-msg restart 
    if [ -x ~/.cache/xwallpaper ];then
        sleep 1
        ~/.cache/xwallpaper
    fi
fi
