#!/usr/bin/env bash
set -e
default_target=~/Pictures/wallpapers
cache=~/.cache/xwallpaper

get_path() {
    # find -L "$1" -iregex '.*\.\(jpg\|png\)' -printf '%h\n' | sort -u | dmenu -c -i -l 20 -n
    {
        [ "$1" != "." ] && printf '%s\0' "$1";
        find -L "$@" -iregex '.*\.\(jpg\|png\)' -printf '%h\0';
    } | sort -uz | xargs -r0 basename -a | sort -u | grep -v '^$' | dmenu -c -i -l 20 -n |
        tr \\n \\0 | xargs -r0I{} find -L "$@" -name '{}' -print0 | sort -zV
}
get_wallpaper() {
    find -L "$@" -iregex '.*\.\(jpg\|png\)' | shuf -n1
}
export -f get_wallpaper

declare -a opts=()
declare -a targets=()
while [ $# -gt 0 ];do
    case "$1" in
        -h|--help) printf 'Usage: %s [--sxiv --dmenu --<xwallpaper option>] IMAGE\n' "${0##*/}"; exit 0 ;;
        --dmenu) use_dmenu=y ;;
        --sxiv) use_sxiv=y ;;
        --current) current=y ;;
        -*) opts+=("$1")        ;; # xwallpaper options
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

if [ "$current" ]; then
    dir=$(grep -oP '(?<= ")/home/.*/' "$cache")
    wallpaper=$(find "$dir" -maxdepth 1 -iregex '.*\.\(jpe?g\|png\)' | shuf -n1)
    [ -f "$wallpaper" ] || exit 1
elif [ "$use_dmenu" ]; then
    wallpaper=$(get_path "${targets[@]}" | xargs -r0I{} bash -c 'get_wallpaper "$@"' _ '{}')
    [ -f "$wallpaper" ] || exit 0
elif [ "$use_sxiv" ]; then
    depth=$(find "${targets[@]}" -iregex '.*\.\(jpg\|png\)' -printf '%d\n' | sort -n | head -1) 
    get_path "${targets[@]}" | xargs -r0 -I '{}' find -L '{}' -maxdepth "$depth" \
        -iregex '.*\.\(jpg\|png\)' -printf '%T@ %p\n' | 
        sort -rn | cut -d' ' -f2- | nsxiv -iqt 2>/dev/null
    exit 0
fi
[ -f "$wallpaper" ] || wallpaper=$(get_wallpaper "${targets[@]}")
wallpaper=$(realpath "$wallpaper")

printf 'xwallpaper %s "%s"' "${opts[*]}" "$wallpaper" > "$cache"
chmod +x "$cache" && "$cache"
cp "$wallpaper" ~/.cache/current_bg.jpg
exit 0
