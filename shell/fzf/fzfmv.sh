#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2162
# shellcheck disable=SC2120
# shellcheck disable=SC2119
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"
declare -r -x THUMB_DIR=~/.cache/fzfvideo
declare -r -x tmpfile=$(mktemp --dry-run)
[ -d "$THUMB_DIR" ] || mkdir -v "$THUMB_DIR"

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

    rm "${UEBERZUG_FIFO}" "$tmpfile" &>/dev/null
}
function calculate_position {
    < <(</dev/tty stty size) \
        read TERMINAL_LINES TERMINAL_COLUMNS

    case "${DEFAULT_PREVIEW_POSITION}" in
        left|up|top) X=1 Y=1 ;;
        right) X=$((TERMINAL_COLUMNS - COLUMNS)) Y=0 ;;
        down|bottom) X=1 Y=$((TERMINAL_LINES - LINES - 1)) ;;
    esac
}
function draw_preview {
    calculate_position
    [ -f "$1" ] || return

    # shellcheck disable=SC2154
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="$(( LINES - 2 ))" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$1")
}
function move() {
    while read -r i;do
        [ -f "$i" ] || continue
        mv -v "$i" "$1"
    done < "$tmpfile"
    read
}
list_dirs() {
    find "${1:-.}" -mindepth 1 -maxdepth 1 -type d ! -path '*/.*'
}
files_to_move() {
    for i in "$@";do
        echo "$i"
    done >> "$tmpfile"
    list_dirs
}
export -f draw_preview calculate_position move files_to_move list_dirs

trap finalise EXIT
start_ueberzug

find "${1:-.}" -maxdepth 1 -iregex '.*\.\(jpg\|png\|jpeg\)' |
    fzf -m --preview "draw_preview {}" \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:60%:border-none" \
    --bind 'enter:execute(move {})' \
    --bind 'ctrl-a:select-all' \
    --bind 'alt-a:deselect-all' \
    --bind 'alt-c:reload(list_dirs {})' \
    --bind 'ctrl-m:reload(files_to_move {+})'
