#!/usr/bin/env bash
source ~/.scripts/shell/fzf/preview.sh
declare -r -x WALL_DIR=~/Pictures/wallpapers
declare -r -x DEFAULT_PREVIEW_POSITION=top

set -e

function preview {
    img=$(find "$1" -iname '*.jpg' | shuf -n1)
    draw_preview "$img"
}
function main {
    find "$1" -type f -iname '*.jpg'
}
export -f preview main

trap finalise EXIT
start_ueberzug

find "$WALL_DIR" -type d |
    fzf --header 'ctrl-x set wallpaper' \
        --preview "preview {}" \
        --preview-window "${DEFAULT_PREVIEW_POSITION}:80%:border-none" \
        --bind='enter:reload(main {})' \
        --bind='ctrl-x:execute(xwall.sh {})'
