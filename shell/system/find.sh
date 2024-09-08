#!/bin/sh
e='.*\.(bdic|tdb|lpl|spl|state[0-9]?|srm|png|jpg|auto|crt|rev|pem|lock|key|[0-9][0-9][0-9]+|log|idx|cache|bin)'

update() {

    find "$path" -type f -size -100k -regextype posix-extended \
        \! \( -path '*/node_modules*' -o -path '*__*__*' -o -path '*/venv/*' -o -path '*/.git/*' -o -iregex "$e" \) |
        while read -r i;do file -bi "$i" | grep -q ^text && printf '%s\n' "$i" ;done | sort -V > "$output"

}

path=$(realpath "$1")
output=${path}/.txt 
[ -s "$output" ] || update
cat "$output"
