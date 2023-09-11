#!/usr/bin/env bash
set -e

PID=$$
LOCK=/tmp/.4ch-dl

echo $PID >> "$LOCK"
while ! head -1 "$LOCK" | grep -qx "$PID" ;do sleep 1; done
trap 'sed -i 1d $LOCK' EXIT

main() {
    [[ "$1" =~ 4chan ]] || return 1

    url="${1%#*}"
    board=$(echo "$url" | grep -oP '(?<=\.org/).*(?=/thread)')
    thread=$(echo "$url" | grep -oP '(?<=/thread/)\d*')
    subject=$(curl -s "https://a.4cdn.org/${board}/catalog.json" |
              jq -r '.[]["threads"][] | select(.no == '"$thread"') | .semantic_url')

    dl_dir=~/Downloads/4ch/"${board}/${thread} ${subject}"

    notify-send "thread: $thread" "$subject"

    curl -L -s "$url" | grep -oP '(?<=href\=")[^"]*\.(jpg|png|gif|webm)' |
        sort -u | xargs -rI{} wget -U Mozilla/5.0 -nc -nv -P "$dl_dir" "https:{}" 2>&1
}
[ -n "$1" ] && main "$1"
