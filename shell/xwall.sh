#!/bin/sh
target=~/Pictures/wallpapers

for arg in "$@";do
    if [ -d "$arg" ];then
        target=$(realpath "$arg")
        wallpaper="$(find -L "$target" -iname '*.jpg' | shuf -n1)"
    elif [ -f "$arg" ];then
        wallpaper=$arg
        break
    fi
done
[ -f "$wallpaper" ] || wallpaper=$(find -L "$target" -iname '*.jpg' | shuf -n1)

for arg in "$@";do
    case "$arg" in
        --dmenu)
            theme=$(find -L "$target" -type d -printf '%f\n' | sort | dmenu -c -i -l 20 -n)
            [ -z "$theme" ] && exit 1
            path=$(find -L "$target" -name "$theme" -type d)
            wallpaper=$(find -L "$path" -iname '*.jpg' | shuf -n1)
        ;;
        --sxiv)
            theme=$(find -L "$target" -type d -printf '%f\n' | sort | dmenu -c -i -l 20 -n)
            [ -z "$theme" ] && exit 1
            path=$(find -L "$target" -name "$theme" -type d)
            wallpaper=$(find -L "$path" -iname '*.jpg' | shuf | nsxiv -ioqt 2>/dev/null)
        ;;
        --*) opt="$arg" ;;
    esac
done

[ -f "$wallpaper" ] || { printf '%s not found\n' "$wallpaper"; exit 1; }
wallpaper=$(realpath "$wallpaper")

[ -f ~/.cache/xwallpaper ] && rm ~/.cache/xwallpaper
echo "xwallpaper ${opt:---stretch} \"$wallpaper\" 2>/dev/null" > ~/.cache/xwallpaper
chmod +x ~/.cache/xwallpaper
~/.cache/xwallpaper

ext=${wallpaper##*.}
cp "$wallpaper" ~/.cache/current_bg."${ext}"
{ pgrep -x i3 && i3-msg reload; } >/dev/null 2>&1 

exit 0
