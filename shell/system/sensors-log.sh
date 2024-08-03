#!/bin/sh
set -e
time=$(date +'%Y/%m/%d %H:%M:%S')
db=~/.cache/sensors.json
new=${db}.bak
tmp=$(mktemp)
trap 'rm $tmp' EXIT
sensors -j > "$tmp"
if ! [ -f "$db" ];then
    jq -r --arg time "$time" '{$time: .}' "$tmp" > "$db"
else
    jq -r -s --arg time "$time" '.[0] + {$time: .[1]}' "$db" "$tmp" > "$new" 
    cp "$new" "$db"
fi
