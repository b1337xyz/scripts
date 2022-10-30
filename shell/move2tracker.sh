#!/usr/bin/env dash
set -e
cd ~/.cache/torrents

find . -maxdepth 1 -type f -iname '*.torrent' | while read -r i
do
    torrent=$(aria2c -S "$i" | awk -F'/' '/ 1\|\.\//{print $2".torrent"}')
    mv -vn -- "$i" "$torrent" || true
done

aria2c -S ./*.torrent | awk '
{
    if ($0 ~ /^Announce:/) {
        getline
        split($0, a, "/")
        split(a[3], b, ":")
        gsub(/\s+$/, "", b[1])
    }
    if ($0 ~ / 1\|\.\//) { 
        split($0, a, "/")
        printf("%s:%s.torrent\n", b[1], a[2])
    }
}' | while read -r i
do
    tracker=${i%%:*}
    tracker=${tracker:-unknown}
    torrent=${i#*:}
    [ -d "$tracker" ] || mkdir -v "$tracker"
    [ -f "$torrent" ] && mv -vf -- "$torrent" "$tracker" || true
done

printf 'please wait...\n'
aria2c -S ~/.cache/torrents/*/*.torrent | awk -F'|' '/[0-9]\|\.\//{print $2}' > torrents.txt
