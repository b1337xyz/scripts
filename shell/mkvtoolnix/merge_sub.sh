#!/usr/bin/env bash
set -e

declare -a opts=()

while [ -n "$1" ];do
    if [ -f "$1" ];then
        mimetype=$(file -Lbi -- "$1" 2>&1)
        case "$mimetype" in
            video/*) video="$1" ;;
            text/*|*charset=us-ascii) subtitle="$1" ;;
            *) printf 'Invalid file type: %s\n' "$mimetype"; exit 1 ;;
        esac
    else
        case "$1" in
            -l) shift ; opts+=(--language 0:"$1") ;;
            -n|-t) shift ; opts+=(--track-name 0:"$1") ;;
            *) printf 'Invalid option: %s\n' "$1"; exit 1 ;;
        esac
    fi
    shift
done

[[ "${opts[*]}" =~ --language ]] || opts+=(--language 0:por)

out="new_${video##*/}"
[ -f "$out" ] && { printf '%s already exists\n' "$out"; exit 1; }
mkvmerge -o "$out" "$video" "${opts[@]}" "$subtitle" || { rm -f "$out"; exit 1; }

rm -i "$video" "$subtitle"
