#!/bin/sh

[ -f "$1" ] || exit 1

set -e

printf 'fetching dad joke...\n'
text=$(curl --user-agent mozilla -s 'https://www.reddit.com/r/ProgrammerDadJokes.json' | 
    jq -c '.data.children[] | "\(.data.title)\n\(.data.selftext)"' | shuf -n1 | sed "s/'//g")
printf '%s\n' "$text"

font=Noto-Sans-Mono-Bold
size=30

printf 'making image...\n'
convert "$1" -blur 0x5 -font "$font" -pointsize "$size" -fill white \
    -gravity center annotate +0+0 "$text" ~/blur.png
