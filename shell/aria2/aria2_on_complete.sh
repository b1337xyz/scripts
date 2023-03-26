#!/usr/bin/env bash

data=$(printf '{"jsonrcp":"2.0", "id":"1", "method":"aria2.removeDownloadResult", "params":[%s]}' "$1")
curl "${HOST:-http://localhost}:${PORT:-6800}/jsonrpc" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$data" 
