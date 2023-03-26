#!/usr/bin/env dash
cd ~/.cache/torrents || exit 1
ls -1 ./*.torrent 2>/dev/null || exit 0

find . -maxdepth 1 -type f -iname '*.torrent' | while read -r i
do
    torrent=$(aria2c -S "$i" | awk -F'/' '/ 1\|\.\//{print $2".torrent"}')
    mv -vf -- "$i" "$torrent"
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
}' | while read -r i
do
    tracker=${i%%:*}
    tracker=${tracker:-unknown}
    torrent=${i#*:}
    if [ -f "$torrent" ] ;then
        [ -d "$tracker" ] || mkdir -v "$tracker"
        mv -vf -- "$torrent" "$tracker"
        [ -f "$torrent" ] && rm -v "$torrent"
    fi
done

printf 'please wait...\n'
aria2c -S ./*/*.torrent | awk -F'|' '/[0-9]\|\.\//{print $2}' > torrents.txt

exit 0
