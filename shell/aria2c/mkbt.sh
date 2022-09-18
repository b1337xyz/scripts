#!/usr/bin/env bash
command -v aria2c &>/dev/null || { printf 'install aria2\n'; exit 1; }
set -eo pipefail

_find() {
    echo -n "$1" | sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 |
        xargs -0roI{} find . -xdev -maxdepth 2 -type f -name '{}'
}

file -Lbi -- "$1" | grep -q bittorrent || { echo "Usage: ${0##*/} TORRENT_FILE"; exit 1; }
torrent=$1
torrent_name=$(aria2c -S "$torrent" | awk -F'/' '/ 1\|\.\//{print $2}')
new_torrent=${torrent_name}.torrent
[ "$new_torrent" != "$torrent" ] && cp -nv "$torrent" "$new_torrent"

# check if all files exist first
declare -a files=()
while read -r i
do
    f=$(_find "${i##*/}")
    [ -f "$f" ] || { printf 'File not found: %s\n' "$f"; exit 1; }
    printf '\e[1;32m:)\e[m %s\n' "$f"
    files+=("$i")
done < <(aria2c -S "$torrent" | awk -F'|' '/[0-9]\|\.\//{print $2}')


for i in "${files[@]}"
do
    d=${i%/*}
    f=$(_find "${i##*/}") 
    [ -d "$d" ] || mkdir -pv "$d"
    mv -nv -- "$f" "$d"
done
