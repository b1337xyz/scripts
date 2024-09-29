#!/bin/sh

while [ $# -gt 0 ];do
    opt=$1 arg=$2
    shift 2
    case "$opt" in
        -b|--background) bg=$arg ;;
        *) [ -f "$opt" ] && file=$opt
    esac
done
[ -f "$file" ] || exit 1
out=new_${file##*/}
convert -background "${bg:-black}" -alpha remove -alpha off "$file" "$out"
