#!/bin/sh
set -e

thread=$(printf '%s' "$1" | grep -oP '(?<=/thread/)\d+')
board=$(printf '%s' "$1" | grep -oP '(?<=/)[^/]*(?=/thread/)')
tmpfile=/tmp/"$thread".json
trap 'rm "$tmpfile" 2>/dev/null' EXIT
curl -s "https://a.4cdn.org/${board}/thread/${thread}.json" > "$tmpfile"
subject=$(jq -r '.posts[0].semantic_url' "$tmpfile")
subject=${subject:-${thread}}
dir="${HOME}/Downloads/4chan/${board}/${subject}"
mkdir -vp "$dir"
cd "$dir"
jq -Mcr '.posts[].com' "$tmpfile" |
    sed 's/<wbr>//g' | grep -oP 'magnet:\?xt=urn:btih:[A-z0-9]+' |
    aria2c -q -d "$dir" --bt-save-metadata --bt-metadata-only --bt-stop-timeout=90 --input-file=- || true

find . -maxdepth 1 -empty -delete

exit 0
