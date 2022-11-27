#!/bin/sh
if xrandr | grep -q 'HDMI1 connected';then
    xrandr --dpi 102 --output eDP1 --auto \
        --output HDMI1 --primary --right-of eDP1 --auto

    pgrep -x i3 && i3-msg restart 
    if [ -x ~/.cache/xwallpaper ];then
        sleep 1
        ~/.cache/xwallpaper
    fi
fi
