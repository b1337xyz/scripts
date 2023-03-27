#!/bin/sh
data=$(printf '{"jsonrpc":"2.0", "id":"1", "method":"aria2.removeDownloadResult", "params":["%s"]}' "$1")
echo "$data"
curl "http://localhost:6802/jsonrpc" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$data" 
