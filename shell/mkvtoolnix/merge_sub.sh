#!/usr/bin/env bash
set -e

while [ "$1" ];do
    mimetype=$(file -Lbi -- "$1" 2>&1)
    case "$mimetype" in
        video/*) vid="$1" ;;
        text/*)  sub="$1" ;;
    esac
    shift
done
sub=${sub:-${vid%.*}.ass}

out=new_${vid##*/}
mkvmerge -o "$out" -a jpn -M -S "$vid" --language 0:por "$sub"

rm -i "$vid" "$sub"
