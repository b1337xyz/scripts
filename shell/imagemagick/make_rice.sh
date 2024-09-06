#!/usr/bin/env bash

output="rice_$(date +%Y%m%d%H%M).jpg"
declare -a arr=()
while IFS= read -d $'\0' -r i;do
    arr+=("$i")
done < <(nsxiv -oqt . 2>/dev/null | tr \\n \\0)
[ "${#arr[@]}" -lt 2 ] && exit 1

case "$1" in
    h|horizontal) magick "${arr[@]}" +append "$output" ;;
    *) magick "${arr[@]}" -append "$output" ;;
esac
