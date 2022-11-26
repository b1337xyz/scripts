#!/usr/bin/env bash
source ~/.scripts/shell/fzf/preview.sh

preview() {
    img=$(find -L "$1" -type f -iregex '.*\.\(jpg\|png\|webp\)' | sort -V | head -1)
    draw_preview "$img"
    for _ in $(seq $((LINES - 1)));do echo ;done
    files=$(find "$1" -type f | wc -l)
    printf 'Files: %s\n' "$files"
}
open() { nsxiv -fqrs w "$1" 2>/dev/null; }
safe_remove() {
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

n=$'\n'
main | fzf --header "ctrl-o open${n}ctrl-r remove" --preview "preview {}" --print0 \
    --preview-window "left:40%:border-none" \
    --border none \
    --bind 'ctrl-r:execute(safe_remove {})+reload(main)' \
    --bind 'ctrl-o:execute(open {})' | xargs -0rI{} nsxiv -rfqs w '{}' 2>/dev/null
