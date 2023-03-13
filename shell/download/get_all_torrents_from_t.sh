#!/bin/sh
set -e

board=t
dir="${HOME}/Downloads/4chan/${board}"
mkdir -vp "$dir"
cd -- "$dir"

curl -s "https://a.4cdn.org/${board}/catalog.json" |
    jq -Mcr '.[].threads[] | "\(.no) \(.semantic_url)"' | while read -r thread subject
do
    echo "$thread: $subject"
    sleep 1
    dir=${subject:-${thread}}
    [ -d "$dir" ] || mkdir -v "$dir"
    curl -s "https://a.4cdn.org/${board}/thread/${thread}.json" | jq -Mcr '.posts[].com' |
        sed 's/<wbr>//g' | grep -oP 'magnet:\?xt=urn:btih:[A-z0-9]+' |
        aria2c -q -d "$dir" --bt-save-metadata --bt-metadata-only --bt-stop-timeout=90 --input-file=- || true

    find . -maxdepth 1 -empty -delete
done

exit 0
