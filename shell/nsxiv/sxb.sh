#!/bin/sh
# https://codeberg.org/nsxiv/nsxiv-extra/src/branch/master/patches/dmenu-search
set -e

if command -v devour >/dev/null 2>&1 && [ -z "$DEVOUR" ];then
    DEVOUR=y exec devour "$0"
fi

tmp=${HOME}/.cache/sxb
# trap 'rm -rf "$tmp"' EXIT

n=1
cwd=$PWD
while :;do
    cache=${tmp}${PWD}/files
    cache_d=${cache}.dir     # directories go first
    mkdir -p "${cache%/*}"
    if [ ! -f "$cache" ];then
        for i in ./*;do
            if [ -d "$i" ];then
                d=$(find -L "$i" -mindepth 1 -maxdepth 1 -type d | shuf -n1)      # choose a random subfolder/title
                find -L "${d:-$i}" -iregex '.*\.\(jpe?g\|png\|webp\)' | sort -V | # get the first image from $d, e.g. 1.jpg
                    head -1 >> "$cache_d"
            else
                echo "$i" >> "$cache"
            fi
        done
        cat "$cache" 2>/dev/null >> "$cache_d" || true
        mv "$cache_d" "$cache"
    fi

    l=$(wc -l < "$cache")
    [ "$l" -eq 0 ] && break

    if [ "$l" -ge 1 ];then
        out=$(nsxiv -n "$n" -fqito < "$cache" 2>/dev/null || { shift; n=$1; })
    elif [ -n "$out" ];then
        out=$(head -1 "$cache")
    fi

    if [ -z "$out" ];then 
        [ "$PWD" = "$cwd" ] && { echo bye; break; }
        n=$1
        cd ..
        shift
        continue
    fi

    x=$(grep -nxF "$out" "$cache") x=${x%%:*}
    out=${out#./*} out=./${out%%/*}
    if [ -d "$out" ];then
        if [ -z "$(find "$out" -mindepth 1 -maxdepth 1 -type d)" ];then
            echo "$out" >> ~/.cache/sxb_history
            find "$out" -iregex '.*\.\(jpe?g\|png\|webp\)' -type f | sort -V |
                zip -q -0 - -@ | zathura --mode=fullscreen -
                # nsxiv -s w -ifbqr 2>/dev/null || true
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
