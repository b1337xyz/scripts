#!/bin/sh

primary=HDMI-A-0
screen=HDMI-A-1-1
dpi=$(xrdb -query | awk '/Xft.dpi:/{print $2}')
dpi=${dpi:-102}

if xrandr | grep -q "${screen} connected";then
    # xrandr --set audio force-dvi ... # to fix overscan ¯\_(ツ)_/¯
    
    xrandr --dpi "${dpi}" --output "$primary" --primary --output "${screen}" --right-of "$primary" --auto
    # xrandr --output "${screen}" --brightness .9

    # if pgrep -x i3; then
    #     i3-msg restart 
    #     [ -x ~/.cache/xwallpaper ] && sleep 1 && ~/.cache/xwallpaper
    # fi
else
    echo "Xft.dpi: ${dpi}" | xrdb -merge
    xrandr --dpi "${dpi}" --output "$primary" --primary 
fi
