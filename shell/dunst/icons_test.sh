#!/bin/bash

fun() {
    notify-send -i "$1" "Notification test" "$1"
}
export -f fun

icon=$(find "$1" -type f | fzf --bind 'ctrl-o:execute-silent(fun {})')
fun "$icon"
echo -n "$icon" | xclip -sel clip
