#!/usr/bin/env bash
[ -z "$1" ] && { printf 'Usage: %s URL|ID\n' "${0##*/}"; exit 1; }
case "$1" in
    https://*id=*)
        FILEID="${1##*id=}"
        FILEID="${FILEID%%&*}"
    ;;
    */file/d/*) FILEID=$(echo -n "$1" | cut -d'/' -f6) ;;
    *) FILEID="$1" ;;
esac
printf 'FILEID: \e[1;31m%s\e[m\n' "$FILEID"
CONFIRM=$(
    wget -q --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate \
        "https://docs.google.com/uc?export=download&id=$FILEID" -O- |
        sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p'
)
[ -z "$CONFIRM" ] && { printf "Can\'t confirm: %s\n" "$1"; exit 1; }

wget -nc --content-disposition --load-cookies /tmp/cookies.txt \
    "https://docs.google.com/uc?export=download&confirm=${CONFIRM}&id=$FILEID"

rm -f /tmp/cookies.txt
