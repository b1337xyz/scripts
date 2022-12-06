#!/usr/bin/env bash
copy() {
    printf '%s' "$*" | xclip -sel clip
    notify-send -i xfce4-clipman-plugin "Copied" "$*"
}
export -f copy
fzf --bind 'enter:execute(copy {})'
