#!/bin/sh

set -xe

tmpfile=$(mktemp)
trap "rm -- $tmpfile" EXIT

curl -s 'https://www.internet-radio.com/stations/' | grep -oP '(?<=href="/stations/)[^/]*' |
while read -r station;do
    url="https://www.internet-radio.com/stations/${station}/"
    curl -s "$url" > "$tmpfile"
    max_page=$(
        grep -oP '(?<=href=")[^"]*page\d*(?=">)' "$tmpfile" |
        sort -t '/' -k 4.5n | tail -1 | grep -oP '(?<=page)\d*'
    )
    printf '"%s":{' "$station"
    for page in $(seq 1 "$max_page");do
        if [ "$page" -gt 1 ];then
            url="https://www.internet-radio.com/stations/${station}/page${page}"
            curl -s "$url" > "$tmpfile"
        fi
        echo "[${page}/${max_page}] $url" 1>&2
        grep -oP "(?<=')http[^'']*\.pls" "$tmpfile" | sort -u | xargs -r curl -s |
            awk -F '=' '{
                if ($0 ~ /^Title/) {
                    gsub(/"/, "", $2)
                    title=$2
                }
                if ($0 ~ /^File/) file=$2
                if (title && file)
                    printf("\"%s\": \"%s\",", title, file)
            }'
    done | sed 's/,$//'
    printf '},'
done | sed 's/^/{; s/,$/}/' | tee ./internet-radio.json
