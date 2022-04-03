#!/usr/bin/env bash

url="${1%#*}"
board=$(echo "$url" | grep -oP '(?<=\.org/).*(?=/thread)')
thread=$(echo "$url" | grep -oP '(?<=/thread/)\d*')
subject=$(curl -s "https://a.4cdn.org/${board}/catalog.json" |
    jq -r '.[]["threads"][] | select(.no == '"$thread"') | .semantic_url | split("")[:60] | add')
subject=${subject:-$thread}
dl_dir=~/Downloads/4ch/"${board}_$(date +%Y%m%d)/${subject}"
curl -L -s "$url" | grep -oP '(?<=href=")[^"]*\.(jpg|png|gif|webm)' | sort -u |
    xargs -P 3 -rI{} wget -nc -nv -P "$dl_dir" "http:{}" 2>&1 | grep -v SSL_INIT
