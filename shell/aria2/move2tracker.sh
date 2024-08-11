#!/bin/sh
cd ~/.cache/torrents || exit 1
ls ./*.torrent >/dev/null 2>&1 || exit 0

find . -maxdepth 1 -type f -iname '*.torrent' | while read -r i
do
    torrent=$(aria2c -S "$i" | awk -F'/' '/ 1\|\.\//{print $2".torrent"}')
    mv -vf -- "$i" "$torrent" || true
done

aria2c -S ./*.torrent 2>/dev/null | awk '
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
}' | while IFS=: read -r tracker torrent
do
    tracker=${tracker:-unknown}
    [ -f "$torrent" ] || continue
    if ! [ -d "$tracker"  ];then
        mkdir -v "$tracker" 2>/dev/null || continue
    fi
    mv -fv -- "$torrent" "$tracker"
done

aria2c -S ./*/*.torrent | awk -F'\\|\\./' '/[0-9]\|\.\//{print $2}' > torrents.txt &

exit 0
