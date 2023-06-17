#!/usr/bin/env dash
set -e

if hash devour && [ -z "$DEVOUR" ];then
    DEVOUR=y devour "$0"; exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

n=1
cwd=$PWD
while :;do
    cache=${tmp}${PWD}/files
    mkdir -p "${cache%/*}"
    if [ ! -f "$cache" ];then
        for i in ./*;do
            d=$(find -L "$i" -mindepth 1 -maxdepth 1 -type d | shuf -n1)
            find -L "${d:-$i}" -iregex '.*\.\(jpe?g\|png\|gif\|webp\)' | sort -V | head -1
        done > "$cache"
    fi

    l=$(wc -l < "$cache")
    [ "$l" -eq 0 ] && break

    if [ "$l" -gt 1 ];then
        out=$(nsxiv -n "$n" -qito < "$cache" 2>/dev/null || true)
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
        if [ -z "$(find "$out" -mindepth 1 -maxdepth 1 -type d)" ];then
            nsxiv -s w -bqr "$out" 2>/dev/null || true
            out=
            n=$x
        else
            cd "$out"
            n=1
            # shellcheck disable=SC2068
            set -- "$x" $@
        fi
    else
        out=
    fi
done
