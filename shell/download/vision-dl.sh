#!/usr/bin/env bash
# shellcheck disable=SC2155
declare -r -x tmpfile=$(mktemp)
declare -r -x MAX_RESULTS=15
declare -r -x UA="Mozilla/5.0 (X11; U; Linux i686) Gecko/20071127 Firefox/2.0.0.11"

# TODO: add options to filter search results
#   - animesvision<dot>biz/search?nome=&tipo=&status=&idioma=&ordenar=padrao&ano_inicial=1917&ano_final=2021&fansub=&temporada=&estudios=&produtores=&generos=
#   - check the api https://animesvision.biz/api/ajax/busca?nome=

end() { rm "$tmpfile"; }
trap end EXIT

download() {
    ep=${1%/*} ep=${ep##*/}
    title=${1%/*} title=${title%/*} title=${title##*/}
    output="${title}_${ep}.mp4"
    [ -f "$output" ] && { printf '%s already exists\n' "$output"; return 1; }

    curl -sS -L "$1" -H "$UA" --compressed |
    grep -Eo "(http|https):\\\\[a-zA-Z0-9./\\\\?=_-]*&amp;expires=[Z0-9]*" |
    tail -n1 | sed -e "s/\\\\//g" -e "s/amp;//g" | xargs -r wget    \
    -U "$UA" -nc -nv --retry-connrefused --waitretry=1              \
    --continue --content-disposition                                \
    --referer="https://ouo.io/" -e robots=off -O "$output"
}
main() { 
    query=$*
    query=${query// /+}
    i=1
    curl -sS -H "$UA" "https://animesvision.biz/search?nome=$query" |
    grep -oE '(http|https)://animesvision.biz/animes/[a-z0-9-]*' | awk '!seen[$0]++' |
    head -n "$MAX_RESULTS" | tee "$tmpfile" | while read -r url
    do
        title=${url##*/} title=${title//-/ }
        printf '%2s) %s\n' "$i" "$title"
        ((i++))
    done
    [ -s "$tmpfile" ] || return 1
    read -r -p ": " n
    lines=$(wc -l "$tmpfile") lines=${lines% *}
    [[ "$n" =~ ^[0-9]* && "$n" -le "$lines" && "$n" -gt 0 ]] ||
        { printf 'Invalid option: %s\n' "$n"; return 1; }

    url=$(sed "${n}!d" "$tmpfile")
    folder=${url##*/}

    [ -d "$folder" ] || mkdir -v "$folder"
    cd "$folder" || return 1
    find . -empty -delete

    i=1
    url=${url}/episodio-01/legendado
    curl -sS -H "$UA" "$url" | grep -Po '(?<=href=")[^"]*(?=")*/legendado' | sort -u > "$tmpfile"
    lines=$(wc -l "$tmpfile") lines=${lines% *}
    while read -r url
    do
        printf '[%3s/%3s] %s\n' "$i" "$lines" "$url"
        download "$url"
        ((i++))
    done < "$tmpfile"
}
main "$@"
