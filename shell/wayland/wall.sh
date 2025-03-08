#!/usr/bin/env bash
set -e
PID=$$
lock=/tmp/.wall.lock/"$PID"
default_target=~/Pictures/wallpapers
cache=~/.cache/swaybg.sh
log=~/.cache/.swaybg.log
reImage='.*\.\(jpe?g\|png\)'
seconds=15

[ -f "$log" ] || :>"$log"

_help()
{
    cat << EOF
Usage: ${0##*/} open [--dark --loop <S> --no-cache --prev --next --current --sxiv --rofi --remove] IMAGE|DIR
EOF

    exit 0
}
get_path()
{
    # same as above but does not show the whole path, just the basename of the images found
    # pipe dirname to basename than find the selected basename in the provided path $@
    { 
        [ "$1" != "." ] && printf '%s\0' "$1";
        find -L "$@" -iregex "$reImage" -printf '%h\0';
    } | sort -uz | xargs -r0 basename -a | sort -u | grep -v '^$' | rofi -dmenu -i -l 20 |
        tr \\n \\0 | xargs -r0I{} find -L "$@" -name '{}' -print0 | sort -zV
}
get_current_wallpaper()
{
    grep -oP '(?<=^>).*' "$log" || grep -oP '(?<= ")/[^"]+\.(jpg|png|jpeg)' "$cache" || exit 1
}
random_wallpaper()
{
    find -L "$@" -iregex "$reImage" | shuf -n1
}
is_dark()
{
    magick "$1" -format "%[fx:int(mean * 100)]" info: | awk '{exit !( ($1 + 0) < 25)}'
}

curr=$(get_current_wallpaper)
declare -a targets=()
while [ $# -gt 0 ];do
    case "$1" in
        open) nsxiv "$curr" ; exit 0 ;;
        -h|--help) _help ;;
        --loop)
            loop=y
            if [[ "$2" =~ ^[0-9]+$ ]];then
                shift
                seconds=$1
            fi
        ;;
        --dark)     dark=y ;;
        --parent)   parent=y ;;
        --prev)     prev=y ;;
        --next)     next=y ;;
        --rofi)     use_rofi=y ;;
        --sxiv)     use_sxiv=y ;;
        --remove)   remove=y ;;
        --current)  current=y ;;  # only look for images in the current wallpaper directory
        --no-cache) no_cache=y; cache=$(mktemp) ;;
        *)
            if [ -d "$1" ];then
                targets+=("$1")
            elif [ -f "$1" ] && file -Lbi "$1" 2>/dev/null | grep -q '^image/';then
                wallpaper=$1
            else
                echo "?"; _help
            fi
        ;;
    esac
    shift
done

if [ -d /tmp/.xwall.lock ];then
    for i in /tmp/.xwall.lock/*;do
        if [ -d "$i" ];then
            { echo "${i##*/}"; ps -o pid= --ppid "${i##*/}"; } | xargs -tr kill
        fi
    done && sleep 1
fi
mkdir -vp "$lock"
end() {
    [ "$no_cache" = y ] && rm -v "$cache"
    rm -d "$lock" && rm -d "${lock%/*}"
}
trap 'end' EXIT

[ -f "$cache" ] || :>"$cache"
test ${#targets[@]} -eq 0 && targets=("$default_target")

if [ "$remove" = y ];then
    if [ -f "$curr" ];then
        if printf 'Yes\nno' | rofi -dmenu -l 2 -i -p "Remove ${curr}?" | grep -q Yes
        then
            rm "$curr" || exit 1
            notify-send "Wallpaper removed" "$curr"
            $0
        fi
    fi
    exit 0
elif [ "$parent" ]
then
    wallpaper=$(random_wallpaper "${curr%/*}")
elif [ "$prev" ] || [ "$next" ]
then
    [ "$prev" ] && n=-1 || n=1
    ln=$(grep -n '^>' "$log" | cut -d':' -f1)
    while :;do
        ln=$(( ln + n ))
        wallpaper=$(sed "${ln}!d" "$log")
        [ -z "$wallpaper" ] && { echo "Nothing previous"; exit 1; }
        [ -f "$wallpaper" ] && break
    done
    sed -i "s/^>//" "$log"
    sed -i "${ln}s/^/>/" "$log"
elif [ "$current" ]
then
    dir=$(grep -oP '(?<= -i .).*(?=. -)' "$cache" | grep -oP '.*/')
    wallpaper=$(find "$dir" -maxdepth 1 -iregex "$reImage" | shuf -n1)
elif [ "$use_rofi" ]
then
    path=$(get_path "${targets[@]}" | tr -d \\0)
    wallpaper=$(random_wallpaper "$path")

elif [ "$use_sxiv" ]
then
    # don't look in sub-directories
    maxdepth=$(find "${targets[@]}" -iregex "$reImage" -printf '%d\n' | sort -n | head -1)
    get_path "${targets[@]}" | xargs -r0 -I '{}' find -L '{}' \
        -maxdepth "$maxdepth" -iregex "$reImage" -printf '%T@\t%p\n' | 
        sort -rn | cut -f2- | nsxiv -iqt 2>/dev/null

    exit 0  # now set the wallpaper with nsxiv
fi

echo "targets: ${targets[*]}"
[ -n "$loop" ] && echo "seconds: $seconds"
while [ -d "$lock" ]
do
    [ -z "$wallpaper" ] && wallpaper=$(random_wallpaper "${targets[@]}")
    [ -s "$wallpaper" ] || exit 0
    wallpaper=$(realpath -s "$wallpaper")
    if [ "$dark" = y ] && ! is_dark "$wallpaper" ;then
        unset wallpaper
        continue
    fi

    printf "#!/bin/sh\npkill -x swaybg\nswaybg -i '%s' -m fill >/dev/null 2>&1 &" \
        "$wallpaper" > "$cache"

    chmod +x "$cache"
    if ! "$cache";then
        unset wallpaper
        continue
    fi

    cp "$wallpaper" ~/.cache/current_bg.jpg
    if [ -z "$prev" ] && [ -z "$next" ];then
        sed -i "s/^>//" "$log"
        echo ">$wallpaper" >> "$log"
    fi

    if [ -z "$loop" ];then
        wallpaper=${wallpaper%/*}
        notify-send -h string:x-canonical-private-synchronous:wall \
            "Wallpaper" "${wallpaper/${HOME}\//}"
        break
    else
        unset wallpaper 
        sleep "${seconds}"
    fi
done

exit 0
