#!/usr/bin/env bash

main() {
    url="${1%#*}"
    board=$(echo "$url" | grep -oP '(?<=\.org/).*(?=/thread)')
    thread=$(echo "$url" | grep -oP '(?<=/thread/)\d*')
    subject=$(curl -s "https://a.4cdn.org/${board}/catalog.json" |
        jq -r '.[]["threads"][] | select(.no == '"$thread"') | .semantic_url | split("")[:60] | add')
    [ -z "$subject" ] && subject=$thread
    dl_dir=~/Downloads/4ch/"${board}_$(date +%Y%m%d)/${subject}"
    curl -L -s "$url" | grep -oP '(?<=href=")[^"]*\.(jpg|png|gif|webm)' |
    sort -u | xargs -P 3 -rI{} wget -nc -q -P "$dl_dir" "http:{}" &>/dev/null
}

while :;do
    clip=$(xclip -sel clip -o 2>/dev/null | grep -oP 'https://boards\.4chan.*\.org/.*/thread/\d*')
    if [ -n "$clip" ];then 
        echo -n | xclip -sel clip 
        echo "$clip"
        main "$clip" &
    fi
    sleep 5
done
