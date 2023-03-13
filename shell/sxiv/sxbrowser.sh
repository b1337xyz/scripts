#!/usr/bin/env dash
set -e
cd "${1:-.}"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ptr='.*\.\(jpe?g\|png\|gif\|webp\)'
n=1
cwd=$PWD
while :;do
    cache=${tmp}${PWD}/files
    mkdir -p "${cache%/*}"
    if ! [ -f "$cache" ];then
        for i in ./*;do
            d=$(find "$i" -mindepth 1 -maxdepth 1 -type d | shuf -n1)
            find "${d:-$i}" -iregex "$ptr" | sort -V | head -1
        done > "$cache"
    fi

    l=$(wc -l < "$cache")
    if [ "$l" -eq 0 ];then
        break
    elif [ "$l" -gt 1 ];then
        out=$(nsxiv -n "$n" -fqito < "$cache" 2>/dev/null)
    elif [ -n "$out" ];then
        out=$(head -1 "$cache")
    fi

    if [ -z "$out" ];then 
        [ "$PWD" = "$cwd" ] && break
        n=$1
        cd ..
        shift
        continue
    fi

    x=$(grep -nxF "$out" "$cache") x=${x%%:*}
    out=${out#./*} out=./${out%%/*}
    if [ -d "$out" ];then
        cd "$out"
        n=1
        # shellcheck disable=SC2068
        set -- "$x" $@
    else
        # nsxiv -fqo "$out" 2>/dev/null
        out=
    fi
done
