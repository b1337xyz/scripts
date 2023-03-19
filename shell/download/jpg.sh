#!/bin/sh
curl -s "$1" | grep -oP 'https://jpg\.fish/img/[^\"]*' | sort -u | while read -r url;do
    printf '%s\n' "$url" >&2
    curl -sL "$url" | grep -oP '(?<=og:image. content=.)[^\"]*'
done | aria2c -j 4 --dir ~/Downloads/jpg.fish --input-file=-
