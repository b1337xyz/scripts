#!/usr/bin/env bash
set -e
default_target=~/Pictures/wallpapers
cache=~/.cache/xwallpaper

get_path() {
    # find -L "$1" -iregex '.*\.\(jpg\|png\)' -printf '%h\n' | sort -u | dmenu -c -i -l 20 -n
    {
        echo -e "$@\0";
        find -L "$@" -iregex '.*\.\(jpg\|png\)' -printf '%h\0';
    } | sort -uz | xargs -r0 basename -a | sort -u | dmenu -c -i -l 20 -n |
        tr \\n \\0 | xargs -r0I{} find -L "$@" -name '{}' -print0
}
get_wallpaper() {
    find -L "$@" -iregex '.*\.\(jpg\|png\)' | shuf -n1
}
export -f get_wallpaper

declare -a opts=()
declare -a targets=()
while [ $# -gt 0 ];do
    case "$1" in
        --dmenu) use_dmenu=1    ;;
        --sxiv)  use_sxiv=1     ;;
        -*) opts+=("$1")        ;;
        *)
            if [ -d "$1" ];then
                targets+=("$1")
            elif file -Lbi "$1" | grep -q '^image/';then
                wallpaper="$1"
            fi
        ;;
    esac
    shift
done
test ${#opts[@]}    -eq 0 && opts=(--stretch)
test ${#targets[@]} -eq 0 && targets=("$default_target")

if test "${use_dmenu:-0}" -eq 1  ;then
    wallpaper=$(get_path "${targets[@]}" | xargs -r0I{} bash -c 'get_wallpaper "$@"' _ '{}')
    [ -f "$wallpaper" ] || exit 0
elif test "${use_sxiv:-0}" -eq 1 ;then
    get_path "${targets[@]}" | xargs -r0 -I '{}' find -L '{}' \
        -iregex '.*\.\(jpg\|png\)' -printf '%T@ %p\n' | 
        sort -rn | cut -d' ' -f2- | nsxiv -iqt 2>/dev/null
    exit 0
fi
[ -f "$wallpaper" ] || wallpaper=$(get_wallpaper "${targets[@]}")
wallpaper=$(realpath "$wallpaper")
echo "xwallpaper ${opts[*]} \"$wallpaper\" 2>/dev/null" > "$cache"
chmod +x ~/.cache/xwallpaper && ~/.cache/xwallpaper
ext=${wallpaper##*.}
cp "$wallpaper" ~/.cache/current_bg."${ext}"
# pgrep -x i3 && i3-msg reload >/dev/null 2>&1 
exit 0
