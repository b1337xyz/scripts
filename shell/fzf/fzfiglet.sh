#!/usr/bin/env bash

declare -r -x TEXT=$*
declare -r -x FONT=~/.local/share/figlet_fonts 

[ -z "$TEXT" ] && { printf 'Usage: %s TEXT\n' "${0##*/}"; exit 1; }

preview() {
    printf '%s\n' "$font"
    figlet -w "$COLUMNS" -f "${FONT}/$1" "$TEXT"
}
export -f preview

font=$(find "$FONT" -type f -printf '%f\n' |
    fzf --preview 'preview {}' --preview-window 'left:80%:border-none')

[ -n "$font" ] && preview "$font"
