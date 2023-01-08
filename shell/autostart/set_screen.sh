#!/bin/sh
if xrandr | grep -q 'HDMI1 connected';then
    # xrandr --set audio force-dvi ... # to fix overscan ¯\_(ツ)_/¯
    
    dpi=$(xrdb -query | awk '/Xft.dpi:/{print $2}')

    # HDMI1 right of eDP1
    xrandr --dpi "${dpi:-96}" --output eDP1 --auto \
        --output HDMI1 --primary --right-of eDP1 --auto
    
    # HDMI1 only
    # xrandr --dpi "${dpi:-96}" --output eDP1 --off \
    #     --output HDMI1 --primary --auto

    pgrep -x i3 && i3-msg restart 
    [ -x ~/.cache/xwallpaper ] && sleep 1 && ~/.cache/xwallpaper

    $(conky >/dev/null 2>&1 &)
    $(conky -c ~/.config/conky/conky.2.conf >/dev/null 2>&1 &)
else
    echo "Xft.dpi: 102" | xrdb -merge
fi
