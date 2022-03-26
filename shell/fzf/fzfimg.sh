#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")
declare -r -x PREVIEW_ID="preview"
declare -r -x TARGET="${1:-.}"

function start_ueberzug {
    mkfifo "${UEBERZUG_FIFO}"
    <"${UEBERZUG_FIFO}" \
        ueberzug layer --parser bash --silent &
    # prevent EOF
    3>"${UEBERZUG_FIFO}" \
        exec
}
function finalise {
    3>&- \
        exec
    rm "${UEBERZUG_FIFO}" &>/dev/null

    # shellcheck disable=SC2046
    kill $(jobs -p) &>/dev/null
}
function calculate_position {
    < <(</dev/tty stty size) \
        read -r TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION}" in
        left|up|top) X=1 Y=1 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS - 2)) Y=1 ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1)) ;;
    esac
}
function draw_preview {
    calculate_position

    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="${@}")
}
function copy {
    t=$(file -Lbi "$1"  | cut -d';' -f1)
    xclip -t "$t" -sel clip "$1"
}
function find_imgs {
    find "$TARGET" -iregex '.*\.\(jpg\|png\|jpeg\)' | sort -V
}
export -f draw_preview calculate_position find_imgs copy

trap finalise EXIT
start_ueberzug

main() {
    fzf -e --preview "draw_preview {}" \
        --preview-window "${DEFAULT_PREVIEW_POSITION}:60%" \
        --bind 'ctrl-r:reload(find_imgs)' \
        --bind 'ctrl-x:execute(xwall.sh {})' \
        --bind 'ctrl-s:reload(find_imgs | shuf)' \
        --bind 'alt-c:execute(copy {})' 
}

case "$1" in
    -)
        main </dev/stdin
    ;;
    *)
        find_imgs | main
    ;;
esac

