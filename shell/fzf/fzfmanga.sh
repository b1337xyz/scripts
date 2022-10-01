#!/usr/bin/env bash
source ~/.scripts/shell/fzf/preview.sh

function preview {
    img=$(find -L "$1" -iregex '.*\.\(jpg\|png\|webp\|gif\)' | sort -V | head -1)
    draw_preview "$img"
    for _ in $(seq $((LINES - 1)));do echo ;done
    files=$(find "$1" -type f | wc -l)
    printf 'Files: %s\n' "$files"
}
function open { nsxiv -fqrs w "$1" 2>/dev/null; }
function safe_remove() {
    local target
    target=$(realpath -- "$1")
    [ -d "$target" ] || return 1
    find "$target" -maxdepth 1 -iregex '.*\.\(jpg\|png\)' -delete
    rm -dI "$target"
}
main() { find . -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | sort -V; }
export -f main preview open safe_remove
trap finalise EXIT
start_ueberzug

main | fzf --preview "preview {}" --print0 \
    --preview-window "left:40%:border-none" \
    --border none \
    --bind 'ctrl-d:execute(safe_remove {})+reload(main)' \
    --bind 'ctrl-o:execute(open {})' | xargs -0rI{} nsxiv -rfqs w '{}' 2>/dev/null
