#!/usr/bin/env bash
default_target=~/Pictures/wallpapers
cache=~/.cache/setwall
log=~/.cache/.swaybg.log
reImage='.*\.\(jpe?g\|png\)'

[ -f "$cache" ] || :>"$cache"

_help() {
    printf 'Usage: %s --rofi --no-cache --prev --next --current --sxiv IMAGE|DIR\n' "${0##*/}"
    exit 0
}
get_path() {
    { 
        [ "$1" != "." ] && printf '%s\0' "$1";
        find -L "$@" -iregex "$reImage" -printf '%h\0';  # %h = dirname
    } | sort -uz | xargs -r0 basename -a | sort -u | grep -v '^$' | rofi -dmenu -i -l 20 |
        tr \\n \\0 | xargs -r0I{} find -L "$@" -name '{}' -print0 | sort -zV
}
get_current_wallpaper() {
    grep -oP '/home[^ ]+\.(jpg|png)' "$cache"
}
random_wallpaper() {
    find -L "$@" -iregex "$reImage" | shuf -n1
}

curr=$(get_current_wallpaper)
declare -a targets=()
while [ $# -gt 0 ];do
    case "$1" in
        open) nsxiv "$curr" ; exit 0 ;;
        -h|--help)  _help ;;
        --parent)   parent=y ;;
        --prev)     prev=y ;;
        --next)     next=y ;;
        --current)  current=y ;;  # only look for images in the current wallpaper directory
        --no-cache) cache=$(mktemp); trap 'rm $cache' EXIT ;;
        --sxiv)     use_sxiv=y ;;
        -i|--rofi)  use_rofi=y ;;
        *)
            if [ -d "$1" ];then
                targets+=("$1")
            elif file -Lbi "$1" | grep -q '^image/';then
                wallpaper=$1
            fi
        ;;
    esac
    shift
done

test ${#targets[@]} -eq 0 && targets=("$default_target")

if [ "$parent" ]; then
    wallpaper=$(random_wallpaper "${curr%/*}")
elif [ "$prev" ]; then
    wallpaper=$(grep -xF "$curr" "$log" -B1 | tail -2 | head -1)
elif [ "$next" ]; then
    wallpaper=$(grep -xF "$curr" "$log" -A1 | tail -1)
elif [ "$current" ]; then
    dir=${curr%/*}
    wallpaper=$(find "$dir" -maxdepth 1 -iregex "$reImage" | shuf -n1)
elif [ "$use_sxiv" ]
then
    # don't look in sub-directories
    maxdepth=$(find "${targets[@]}" -iregex "$reImage" -printf '%d\n' | sort -n | head -1)
    get_path "${targets[@]}" | xargs -r0 -I '{}' find -L '{}' \
        -maxdepth "$maxdepth" -iregex "$reImage" -printf '%T@\t%p\n' | 
        sort -rn | cut -f2- | nsxiv -iqt 2>/dev/null

    exit 0  # set the wallpaper with nsxiv
elif [ "$use_rofi" ]; then
    path=$(get_path "${targets[@]}" | tr -d \\0)
    wallpaper=$(random_wallpaper "$path")
elif [ -z "$wallpaper" ]
then
    wallpaper=$(random_wallpaper "${targets[@]}")
fi

[ -f "$wallpaper" ] || exit 0
wallpaper=$(realpath -s "$wallpaper")

# printf 'timeout 10 swaymsg output \* bg "%s" fill' "$wallpaper" > "$cache"
printf "#!/bin/sh\npkill -x swaybg\nswaybg -i '%s' -m fill >/dev/null 2>&1 &" \
    "$wallpaper" > "$cache"
chmod +x "$cache" && "$cache"
cp "$wallpaper" ~/.cache/current_bg.jpg
[ -z "$prev" ] && [ -z "$next" ] && echo "$wallpaper" >> "$log"

wallpaper=${wallpaper%/*}
notify-send -i image -r 1338 "XWall" "${wallpaper/${HOME}\//}"
exit 0
