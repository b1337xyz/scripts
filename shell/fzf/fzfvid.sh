#!/usr/bin/env bash
source ~/.scripts/shell/fzf/preview.sh
declare -r -x DEFAULT_PREVIEW_POSITION="right"
declare -r -x THUMB_DIR=~/.cache/thumbnails/fzf
declare -r -x list=$(mktemp)
[ -d "$THUMB_DIR" ] || mkdir -v "$THUMB_DIR"

preview() {
    img=$(tail -c 100 "$1" | md5sum | awk '{print $1".jpg"}')
    img="${THUMB_DIR}/$img"
    [ -f "$img" ] || ffmpegthumbnailer -s 300 -i "$1" -q 10 -o "$img"
    draw_preview "$img"
}
sort_by_size() {
    tr \\n \\0 < "$list" | du --files0-from=- |
        sort -rn | cut -d $'\t' -f2-
}
main() {
    find . -maxdepth 1 -iregex '.*\.\(mp4\|gif\|mov\|mkv\|webm\)'
}
export -f preview sort_by_size main

trap finalise EXIT
start_ueberzug

main | fzf -m --preview "preview {}" \
    --header '^p ^r ^s' \
    --border=none \
    --disabled \
    --preview-window "${DEFAULT_PREVIEW_POSITION}:60%:border-sharp" \
    --bind 'ctrl-a:select-all' \
    --bind 'alt-a:deselect-all' \
    --bind 'ctrl-p:execute-silent(mpv {+})' \
    --bind 'ctrl-s:reload(sort_by_size)' \
    --bind 'ctrl-r:execute(rm {+})+reload(main)'

