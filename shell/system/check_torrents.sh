#!/usr/bin/env bash

torrents=~/.local/share/qBittorrent/BT_backup
downloads=~/Downloads/torrents

grep -vFf \
    <(aria2c -S "$torrents"/*.torrent | awk '/[0-9]*\|\.\//{ split($0, a, "/"); print a[length(a)] }') \
    <(find "$downloads" -type f -printf '%f\n') |
    sed -e 's/[]\[?\*\$]/\\&/g' | xargs -rI{} find "$downloads" -name '{}'

find "$torrents" -name '*.torrent' | wc -l
