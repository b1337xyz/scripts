#!/usr/bin/env bash
copy() {
    printf '%s' "$*" | xclip -sel clip
    notify-send -i clipman "Copied" "$*"
}
export -f copy
fzf --bind 'enter:execute(copy {})'
