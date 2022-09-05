#!/usr/bin/env bash
copy() {
    notify-send -i xfce4-clipman-plugin "Text copied" "$*"
    echo "$*" | xclip -sel clip
}

export -f copy
fzf --bind 'enter:execute(copy {})'
