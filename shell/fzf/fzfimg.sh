#!/usr/bin/env bash
source ~/.scripts/shell/fzf/preview.sh
declare -r -x DEFAULT_PREVIEW_POSITION="left"

function copy {
    t=$(file -Lbi -- "$1" | cut -d';' -f1)
    xclip -t "$t" -sel clip "$1"
}
function find_imgs {
    find "${1:-.}" -iregex '.*\.\(jpg\|png\|jpeg\)' | sort -V
}
export -f find_imgs copy

trap finalise EXIT
start_ueberzug

main() {
    fzf -e --preview "draw_preview {}" \
        --preview-window "${DEFAULT_PREVIEW_POSITION}:60%" \
        --bind 'ctrl-r:reload(find_imgs)' \
        --bind 'ctrl-x:execute(xwall.sh {})' \
        --bind 'ctrl-s:reload(find_imgs | shuf)' \
        --bind 'ctrl-d:execute(rm {})+reload(find_imgs)' \
        --bind 'alt-c:execute(copy {})' 
}

case "$1" in
    -) main </dev/stdin ;;
    *) find_imgs "$@" | main ;;
esac
