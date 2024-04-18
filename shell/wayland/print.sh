#!/usr/bin/env bash
set -x
DIR=~/Pictures/Screenshots
[ -d "$DIR"  ] || mkdir -vp "$DIR"
image="${DIR}/scr_$(date +%Y.%m.%d_%H%M%S).png"

get_focused_geometry() {
    swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
}

case "$1" in
    -*|help) printf 'Usage: %s [focused|select|copy|copf|selc]\n' "${0##*/}"; exit 0 ;;
    foc*) get_focused_geometry | grim -g - "$image" ;;
    sel*) slurp | grim -g - "$image" ;;
    copf) get_focused_geometry | grim -g - - | wl-copy ;;
    cops) slurp | grim -g - - | wl-copy ;;
    copy) grim - | wl-copy ;;
    [0-9]*) sleep "$1"; bash "$0" ;;
    *) grim "$image" ;;
esac

[ -f "$image" ] && notify-send -i "$image" "$(date)" "$image"

exit 0
