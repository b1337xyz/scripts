#!/bin/sh
# shellcheck disable=SC2317
command -v jq >/dev/null 2>&1 || { printf 'install jq\n'; exit 1; }
SCRIPT=${0##*/}
usage() {
    printf 'Usage: %s [board] [-e|--extentions "jpg|png|gif|webm"]\nBoards:\n' "$SCRIPT"
    curl -s 'https://a.4cdn.org/boards.json' | jq -r '.[][]["board"]' | pr -t5
    exit 1
}

extentions='jpg|png|gif|webm'
while [ $# -gt 0 ];do
    case "$1" in
        -e|--extentions) shift; extentions=$1 ;;
        [A-z]*) board=$1 ;;
        -*) usage ;;
    esac
    shift
done
[ -z "$board" ] && usage

tmpfile=$(mktemp)
end() { rm "$tmpfile"; }
trap end EXIT

main_dl_dir=~/Downloads/4ch/"${board}_$(date +%Y%m%d)"
curl -s "https://a.4cdn.org/${board}/catalog.json" |
    jq -Mcr '.[]["threads"][] | "\(.no),\(.semantic_url[:60])"' >> "$tmpfile"
[ -s "$tmpfile" ] || { printf 'nothing found\n'; exit 1; }
tot=$(wc -l < "$tmpfile")
c=1
while IFS=',' read -r thread subject;do
    url="https://boards.4chan.org/${board}/thread/${thread}"
    dl_dir=${main_dl_dir}/${subject:-${thread}}
    printf '%s\n[%s - %s] \e[1;32m%s\e[m\n' "$dl_dir" "$c" "$tot" "$url"

    curl -L -s "$url" | grep -oP '(?<=href=")[^"]*\.('"${extentions}"')' | sort -u |
        xargs -P 3 -rI{} wget -nc -q -P "$dl_dir" "http:{}" 2>&1 | grep -v SSL_INIT

    c=$((c+1))
done < "$tmpfile"

exit 0
