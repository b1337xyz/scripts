#!/usr/bin/env bash

find_torrent() {
    torrent=${1//\[/\\[}        torrent=${torrent//\]/\\]}
    torrent=${torrent//\*/\\*}  torrent=${torrent//\$/\\$}
    torrent=${torrent//\?/\\?}   

    find ~/.cache/torrents -type f -name "$torrent"
}
preview() {
    torrent=$(find_torrent "$1")
    [ -n "$torrent" ] &&
        aria2c -S "$torrent"
}
get_torrents() {
    find ~/.cache/torrents/"$1" -iname '*.torrent' -printf '%f\n' | sort
}
get_trackers() {
    find ~/.cache/torrents -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}
export -f preview find_torrent get_torrents get_trackers

torrent=$(
    get_trackers | fzf --preview 'preview {}' --preview-window 'right:50%' \
    --bind 'enter:reload(get_torrents {})' \
    --bind 'ctrl-r:reload(get_trackers {})'
)

find_torrent "$torrent"
