#!/bin/sh
file=$(find ~/.scripts/shell -type f -name '*.sh' |
       dmenu -c -l 15 -i -n)

[ -f "$file" ] || exit 0
setsid -f -- "${TERMINAL:-xterm}" -e "${EDITOR:-vi}" "$file"
