#!/usr/bin/env bash
# shellcheck disable=SC2155
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x UEBERZUG_FIFO=$(mktemp --dry-run --suffix "fzf-$$-ueberzug")
declare -r -x PREVIEW_ID="preview"

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
    exit 0
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
f() {
    find ~/Pictures/wallpapers -mindepth 1 -type d
}
wallpapers() {
    if [ -z "$1" ];then
        f
    elif [ -d "$1" ];then
        find "$1" -iname '*.jpg'
    elif [ -f "$1" ];then
        convert "$1" -resize 1366x768\! ~/.cache/screen_locker.png
    fi
    finalise
}
function preview {
    if [ -d "$1" ];then
        img=$(find "$1" -iname '*.jpg' | shuf -n1)
    else
        img=$1
    fi

    calculate_position

    # shellcheck disable=SC2154
    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="${X}" [y]="${Y}" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=fit_contain [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$img")
}
export -f preview calculate_position wallpapers f

trap finalise EXIT SIGINT
start_ueberzug

f | fzf --preview "preview {}" \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:60%:border-sharp" \
    --bind 'enter:reload(wallpapers {})' \
    --bind 'esc:reload(wallpapers)'
