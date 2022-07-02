#!/usr/bin/env bash
[ -f "$1" ] || { printf 'Usage: %s image\n'; "${0##*/}"; exit; }

font="/usr/share/fonts/TTF/mononoki-Regular Nerd Font Complete.ttf"
size=18

printf 'fetching dad joke...\n'
text=$(
    curl --user-agent mozilla -s 'https://www.reddit.com/r/ProgrammerDadJokes.json' | 
    jq -Mc '.data.children[] | "\(.data.title)\n\(.data.selftext)"' |
    shuf -n1 | tr -d "'" | tr -d '"'
)
max=60
if [ ${#text} -gt "$max" ];then # brake lines
    c=1
    new_text=
    for ((i=0; i < ${#text}; i++));do
        [ "${text:i:2}" = "\n" ] && c=1
        if [ "$c" -ge "$max" ];then
            new_text+="-\n"
            c=1
        fi
        new_text+="${text:i:1}"
        c=$((c+1))
    done
    text="${new_text}"
fi
printf '%s\n' "$text"
printf 'making image...\n'
output="${1##*/}"
output="${output%.*}_dadjoke_$(date +%Y%m%d%H%M).png"
convert "$1" -blur 0x4 -font "$font" -pointsize "$size" -fill white \
    -gravity center -annotate +0+0 "$text" "$output"
