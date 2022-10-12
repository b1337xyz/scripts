#!/usr/bin/env bash
source ~/.scripts/shell/fzf/preview.sh
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x THUMB_DIR=~/.cache/thumbnails/fzf
[ -d "$THUMB_DIR" ] || mkdir -vp "$THUMB_DIR"

WALLPAPERS=~/Videos/wallpapers

function preview {
    img="$THUMB_DIR/${1##*/}"
    [ -f "$img" ] || ffmpegthumbnailer -s 300 -i "$1" -o "$img"

    draw_preview "$img"
}
export -f preview 

trap finalise EXIT
start_ueberzug

find "${1:-$WALLPAPERS}" -iregex '.*\.\(mkv\|avi\|mp4\|webm\|gif\)' |
    sort -V | fzf --preview "preview {}" \
    --border=none \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:45%:border-sharp" \
    --bind 'ctrl-h:execute-silent(vbg.sh -s hdmi1 {})' \
    --bind 'enter:execute-silent(vbg.sh {})'
