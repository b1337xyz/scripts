#!/bin/sh
# shellcheck disable=SC2016

set -e

command -v scrot >/dev/null 2>&1 || { printf 'install scrot\n'; exit 1; }
command -v xclip >/dev/null 2>&1 || { printf 'install xclip\n'; exit 1; }

DIR=~/Pictures/screenshots
[ -d "$DIR"  ] || mkdir -vp "$DIR"

notify() {
    size=$(du -sh "$1" | awk '{print $1}')
    notify-send -i "$1" "$(date +%Y.%m.%d)" "$2\n$size"
}
export -f notify
cmd='notify "$f" "$wx$h"'
cmd2='xclip -sel clip -t image/png -i $f; notify $f "$wx$h"'

tmpimg="/tmp/screenshot_%Y%m%d%H%M.png"
case $1 in
    -*)
        printf 'Usage: %s [focused|select|copy|copy-focused|copy-select]\n' "${0##*/}"
        exit 0
    ;;
    focused)
        scrot -q 100 -u ~/Pictures/screenshots/screenshot_%H%M%S_%d%m%Y.png -e "$cmd"
    ;;
    select|sel)
        sleep 1 ; scrot -q 100 -s ~/Pictures/screenshots/screenshot_%Y%m%d%H%M.png -e "$cmd"
    ;;
    copy)
        scrot -q 100  "$tmpimg" -e "$cmd2"
    ;;
    copy-focused|copf)
        scrot -q 100 -u "$tmpimg" -e "$cmd2"
    ;;
    copy-select|selc)
        sleep .5 ; scrot -q 100 -s "$tmpimg" -e "$cmd2"
    ;;
    *)
        scrot -q 100 -m ~/Pictures/screenshots/screenshot_%Y%m%d%H%M.png -e "$cmd"
    ;;
esac

[ -f "$tmpimg" ] && sleep 60 && rm "$tmpimg"
