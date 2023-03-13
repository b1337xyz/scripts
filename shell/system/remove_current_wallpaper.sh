#!/usr/bin/env bash
curr_wallpaper=$(awk -F'"' '{print $2}' ~/.cache/xwallpaper)
if [ -f "$curr_wallpaper" ];then
    # sxiv -fopq "$curr_wallpaper" | xargs -rI{} rm -v {} 2>&1 | xargs -r notify-send
    if [ $(printf 'Yes\nno' | dmenu -i -p "remove \"$curr_wallpaper\"?") = "Yes" ];then
        rm -v "$curr_wallpaper" | tr \\n \\0 | xargs -0r notify-send -i user-trash
        # xwall.sh
    fi
fi
