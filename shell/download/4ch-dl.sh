#!/usr/bin/env bash
set -e

PID=$$
LOCK=/tmp/.4ch-dl
ICON=~/Pictures/icons/4chan.png

echo $PID >> "$LOCK"
trap 'sed -i 1d $LOCK' EXIT
while ! head -1 "$LOCK" | grep -qx "$PID" ;do sleep 3; done

main() {
    [[ "$1" =~ 4chan ]] || return 1

    url="${1%#*}"
    board=$(echo "$url" | grep -oP '(?<=\.org/).*(?=/thread)')
    thread=$(echo "$url" | grep -oP '(?<=/thread/)\d*')
    subject=$(curl -s "https://a.4cdn.org/${board}/catalog.json" |
              jq -r '.[]["threads"][] | select(.no == '"$thread"') | .semantic_url')

    dl_dir=~/Downloads/4ch/"${board}/${thread} ${subject}"

    notify-send -i "$ICON" "thread: $thread" "$subject"

    curl -L -s "$url" | grep -oP '(?<=href\=")[^"]*\.(jpg|png|gif|webm)' |
        sort -u | xargs -P2 -rI{} wget -nc -nv -P "$dl_dir" "http:{}" 2>&1 | grep -v SSL_INIT
}
[ -n "$1" ] && main "$1"
