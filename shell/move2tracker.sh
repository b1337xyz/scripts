#!/usr/bin/env dash

set -e

aria2c -S ./*.torrent | awk '
{
    if ($0 ~ /^Announce:/) {
        getline
        # unnecessary 
        # if (! ($0 ~ /^\s(udp|http|https):/)) next
        split($0, a, "/")
        split(a[3], b, ":")
        gsub(/\s+$/, "", b[1])
    }
    if ($0 ~ / 1\|\.\//) { 
        split($0, a, "/")
        printf("%s.torrent|%s\n", a[2], b[1])
    }
}' | while IFS='|' read -r torrent tracker;do
    tracker=${tracker:-unknown}
    [ -d "$tracker" ] || mkdir -v "$tracker"
    [ -f "$torrent" ] && mv -vn "$torrent" "$tracker"
done
