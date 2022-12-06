#!/bin/sh
# shellcheck disable=SC2016

set -e

command -v scrot >/dev/null 2>&1 || { printf 'install scrot\n'; exit 1; }
command -v xclip >/dev/null 2>&1 || { printf 'install xclip\n'; exit 1; }

DIR=~/Pictures/screenshots
[ -d "$DIR"  ] || mkdir -vp "$DIR"

tmpimg="/tmp/screenshot_%Y%m%d%H%M.png"
case $1 in
    -*)
        printf 'Usage: %s [focused|select|copy|copy-focused|copy-select]\n' "${0##*/}"
        exit 0
    ;;
    focused)
        scrot -q 100 -u ~/Pictures/screenshots/screenshot_%H%M%S_%d%m%Y.png -e 'notify-send -i $f Print $f'
    ;;
    select|sel)
        sleep 1 ; scrot -q 100 -s ~/Pictures/screenshots/screenshot_%Y%m%d%H%M.png -e 'notify-send -i $f Print $f'
    ;;
    copy)
        scrot -q 100  "$tmpimg" \
            -e 'xclip -sel clip -t image/png -i $f; notify-send -i $f Print $f'
    ;;
    copy-focused|copf)
        scrot -q 100 -u "$tmpimg" \
            -e 'xclip -sel clip -t image/png -i $f; notify-send -i $f Print $f'
    ;;
    copy-select|selc)
        sleep .5 ; scrot -q 100 -s "$tmpimg" \
            -e 'xclip -sel clip -t image/png -i $f; notify-send -i $f Print $f'
        ;;
    *) scrot -q 100 -m ~/Pictures/screenshots/screenshot_%Y%m%d%H%M.png -e 'notify-send -i $f Print $f' ;;
esac

[ -f "$tmpimg" ] && sleep 5m && rm "$tmpimg"
