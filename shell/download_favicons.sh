#!/usr/bin/env bash

set -e

src=$(realpath "$1")
[ -d icons ] || mkdir -v icons
cd icons

grep -oP '(?<=href=")http.*(?=")' "$src" | sed 's/\/$//g; s/$/\//g' | cut -d'/' -f-3 | sort -u | while read -r url;do
    out="${url##*/}.ico"
    [ -f "${out%.*}.png" ] && continue
    if curl -sL "$url/favicon.ico" -o "$out" ;then
        if file -bi "$out" | grep -q ^image;then
            printf '\033[1;32mSuccess\033[m %s\n' "$url"
            if ! file -bi "$out" | grep -q image/png;then
                convert "${out}[-1]" "${out%.*}.png"
                rm "$out"
            else
                mv "$out" "${out%.*}.png"
            fi
        else
            printf '\033[1;31mFailed\033[m %s\n' "$url"
            rm "$out"
        fi
    else
        printf '\033[1;31mFailed\033[m %s\n' "$url"
    fi
done
