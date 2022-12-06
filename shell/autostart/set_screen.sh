#!/bin/sh
if xrandr | grep -q 'HDMI1 connected';then
    # --set audio force-dvi # to fix overscan ¯\_(ツ)_/¯
    
    dpi=$(xrdb -query | awk '/Xft.dpi:/{print $2}')

    # HDMI1 right of eDP1
    xrandr --dpi "${dpi:-96}" --output eDP1 --auto \
        --output HDMI1 --primary --right-of eDP1 --auto
    
    # HDMI1 only
    # xrandr --dpi "${dpi:-96}" --output eDP1 --off \
    #     --output HDMI1 --primary --auto

    pgrep -x i3 && i3-msg restart 
    if [ -x ~/.cache/xwallpaper ];then
        sleep 1
        ~/.cache/xwallpaper
    fi
fi
