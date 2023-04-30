#!/usr/bin/env bash
set -e

ICON=~/Pictures/icons/4chan.png
RPC_HOST=localhost
RPC_PORT=6800

addUri() {
    data=$(printf '{"jsonrpc":"2.0", "id":"1", "method":"aria2.addUri", "params":[["%s"], {"dir": "%s"}]}' "$1" "$2")
    curl -s "http://${RPC_HOST}:${RPC_PORT}/jsonrpc" \
        -H "Content-Type: application/json" -H "Accept: application/json" \
        -d "$data" >/dev/null 2>&1
}

main() {
    [[ "$1" =~ 4chan ]] || return 1
    url="${1%#*}"
    board=$(echo "$url" | grep -oP '(?<=\.org/).*(?=/thread)')
    thread=$(echo "$url" | grep -oP '(?<=/thread/)\d*')
    subject=$(curl -s "https://a.4cdn.org/${board}/catalog.json" |
        jq -r '.[]["threads"][] | select(.no == '"$thread"') | .semantic_url[:60]')
    dl_dir=~/Downloads/4ch/"${board}/${thread} ${subject}"
    notify-send -i "$ICON" "thread: $thread" "$subject"
    curl -L -s "$url" | grep -oP '(?<=href\=")[^"]*\.(jpg|png|gif|webm)' |
    sort -u | xargs -rI{} wget -nc -nv -P "$dl_dir" "http:{}" 2>&1 | grep -v SSL_INIT
}
[ -n "$1" ] && main "$1"
