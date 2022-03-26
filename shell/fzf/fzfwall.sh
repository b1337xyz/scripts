#!/usr/bin/env bash
# shellcheck disable=SC2155
# shellcheck disable=SC2154
declare -r -x UEBERZUG_FIFO="$(mktemp --dry-run --suffix "fzf-$$-ueberzug")"
declare -r -x WALL_DIR=~/Pictures/wallpapers

set -e

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
    kill "$(jobs -p)" &>/dev/null
}
function draw_preview {
    if [ -f "$1" ];then
        img="$1"
    else
        img=$(find "$1" -iname '*.jpg' | shuf -n1)
    fi

    >"${UEBERZUG_FIFO}" declare -A -p cmd=( \
        [action]=add [identifier]="${PREVIEW_ID}" \
        [x]="0" [y]="0" \
        [width]="${COLUMNS}" [height]="${LINES}" \
        [scaler]=cover [scaling_position_x]=0.5 [scaling_position_y]=0.5 \
        [path]="$img")
}
function wallpapers {
    find "$1" -type f -iname '*.jpg'
}
export -f draw_preview wallpapers

trap finalise EXIT
start_ueberzug

find "$WALL_DIR" -type d |
    fzf --header 'ctrl-x set wallpaper' \
        --preview "draw_preview {}" \
        --preview-window "top:80%:border-none" \
        --bind='enter:reload(wallpapers {})' \
        --bind='ctrl-x:execute(xwall.sh {})'
