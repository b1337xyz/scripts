#!/bin/sh
# shellcheck disable=SC2016
set -e

command -v scrot >/dev/null 2>&1 || { printf 'install scrot\n'; exit 1; }
command -v xclip >/dev/null 2>&1 || { printf 'install xclip\n'; exit 1; }

notify() {
    size=$(du -sh "$1" | awk '{print $1}')
    notify-send -i "$1" "$2" "$3\n$size"
}
export -f notify

DIR=~/Pictures/screenshots
[ -d "$DIR"  ] || mkdir -vp "$DIR"
cmd='notify "$f" "$n" "$wx$h"'
cmd2='xclip -sel clip -t image/png -i $f; notify "$f" "$n" "$wx$h"'
image="${DIR}/scr_%Y%m%d%H%M%S.png"
tmpimg="/tmp/scr_%Y%m%d%H%M%S.png"

case "$1" in
    -*|help)
        printf 'Usage: %s [focused|select|copy|copy-focused|copy-select]\n' "${0##*/}"
        exit 0
    ;;
    focused) scrot -q 100 -u "$image" -e "$cmd" ;;
    select|sel) sleep 1 ; scrot -q 100 -s "$image" -e "$cmd" ;;
    copy) scrot -q 100  "$tmpimg" -e "$cmd2" ;;
    copy-focused|copf) scrot -q 100 -u "$tmpimg" -e "$cmd2" ;;
    copy-select|selc) sleep 1 ; scrot -q 100 -s "$tmpimg" -e "$cmd2" ;;
    *) scrot -q 100 -m "$image" -e "$cmd" ;;
esac

[ -f "$tmpimg" ] && sleep 60 && rm "$tmpimg"

exit 0
