#!/usr/bin/env bash
icon=~/Pictures/icons/4chan.png

main() {
    url="${1%#*}"
    [[ "$url" =~ 4chan ]] || return 1

    board=$(echo "$url" | grep -oP '(?<=\.org/).*(?=/thread)')
    thread=$(echo "$url" | grep -oP '(?<=/thread/)\d*')
    subject=$(curl -s "https://a.4cdn.org/${board}/catalog.json" |
        jq -r '.[]["threads"][] | select(.no == '"$thread"') | .semantic_url[:60]')
    dl_dir=~/Downloads/4ch/"${board}/${thread} ${subject}"

    notify-send -i "$icon" "thread: $thread" "$subject"
    curl -L -s "$url" | grep -oP '(?<=href\=")[^"]*\.(jpg|png|gif|webm)' | sort -u |
        xargs -P 3 -rI{} wget -nc -nv -P "$dl_dir" "http:{}" 2>&1 | grep -v SSL_INIT
}
[ -n "$1" ] && main "$1"
