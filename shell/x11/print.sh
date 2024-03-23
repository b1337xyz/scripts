#!/usr/bin/env bash
hash scrot || { printf 'install scrot\n'; exit 1; }
hash xclip || { printf 'install xclip\n'; exit 1; }

DIR=~/Pictures/screenshots
[ -d "$DIR"  ] || mkdir -vp "$DIR"
cmd='notify-send -i "$f" "$n" "$wx$h\n$s"'
copy='xclip -sel clip -t image/png -i $f; notify-send -i "$f" "$n" "$wx$h\n$s"'
image="${DIR}/scr_%Y.%m.%d_%H%M%S.png"
tmpimg=/tmp/scr_$(date +%Y%m%d%H%M%S).png

sleep .2
case "$1" in
    -*|help) printf 'Usage: %s [focused|select|copy|copf|selc]\n' "${0##*/}"; exit 0 ;;
    foc*) scrot -u "$image"  -e "$cmd" ;;
    sel*) scrot -f -s "$image"  -e "$cmd" ;;
    copf) scrot -u "$tmpimg" -e "$copy" ;;
    cops) scrot -f -s "$tmpimg" -e "$copy" ;;
    copy) scrot -m "$tmpimg" -e "$copy" ;;
    [0-9]*) sleep "$1"; bash "$0" ;;
    *) scrot -m "$image"  -e "$cmd" ;;
esac

[ -f "$tmpimg" ] && sleep 30 && rm "$tmpimg"

exit 0
