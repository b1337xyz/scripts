#!/bin/sh
scr0="HDMI-A-0" # primary
scr1="HDMI-A-1-1"

mode=$(cat << EOF | dmenu -c -i -l 5 | cut -d':' -f1
1: $scr1 left of $scr0
2: $scr1 right of $scr0
3: $scr1 only
4: $scr0 only
5: $scr1 same as $scr0
EOF
)
[ -z "$mode" ] && exit 1
dpi=$(xrdb -query | awk '/Xft.dpi:/{print $2}')
dpi=${dpi:-96}

case "$mode" in
    1) xrandr --dpi "$dpi" --output "$scr0" --primary --auto --output "$scr1" --left-of "$scr0" --auto ;;
    2) xrandr --dpi "$dpi" --output "$scr0" --primary --auto --output "$scr1" --right-of "$scr0" --auto ;;
    3) xrandr --dpi "$dpi" --output "$scr0" --off --output "$scr1" --primary --auto ;;
    4) xrandr --dpi "$dpi" --output "$scr0" --primary --auto --output "$scr1" --off;;
    5) xrandr --dpi "$dpi" --output "$scr1" --same-as "$scr0" ;;
    *) exit 1 ;;
esac

pgrep -x i3 && i3-msg restart 
sleep 1 && ~/.cache/xwallpaper
