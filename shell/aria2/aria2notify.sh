#!/bin/sh
sleep 1

HOST=http://localhost
PORT=6801

send() {
    data=$(printf '{"jsonrcp":"2.0", "id":"1", "method":"aria2.%s", "params":[%s]}' \
           "$1" "$2")
    curl "${HOST:-http://localhost}:${PORT:-6800}/jsonrpc" \
        -H "Content-Type: application/json" -H "Accept: application/json" \
        -d "$data" 
}
addUri() { send addUri "[\"$1\"]"; }
tellStatus() { send tellStatus "\"$1\""; }
removeDownloadResult() { send removeDownloadResult "\"$1\""; }
