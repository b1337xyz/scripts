#!/usr/bin/env bash
source ~/.scripts/shell/fzf/preview.sh

fun() {
    notify-send -i "$1" "Notification test" "$1"
    echo -n "$1" | xclip -sel clip
}
export -f fun
trap finalise EXIT
start_ueberzug

d=$(find /usr/share/icons ~/.local/share/icons -mindepth 1 -maxdepth 1 -type d | fzf)
test -d "$d" || exit 0
find "$d" -type f | fzf -e      \
    --preview 'draw_preview {}' \
    --preview-window 'left:10%' \
    --bind 'Return:execute-silent(fun {})'
