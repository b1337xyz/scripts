#!/usr/bin/env bash
[ -z "$1" ] && { printf 'Usage: %s URL|FILEID\n' "${0##*/}"; exit 1; }

case "$1" in
    *[\&\?]id=*) FILEID=$(echo "$1" | grep -oP '(?<=[\?&]id=)[^&$]*')    ;;
    */folders/*) FILEID=$(echo "$1" | grep -oP '(?<=/folders/)[^\?$/]*') ;;
    */file/d/*)  FILEID=$(echo "$1" | grep -oP '(?<=/file/d/)[^/\?$]*')  ;;
    *) FILEID="$1" ;;
esac
printf 'FILEID: \e[1;31m%s\e[m\n' "$FILEID"

if hash gdrive; then
    # https://github.com/prasmussen/gdrive
    gdrive files download --recursive "$FILEID"
else
    printf 'gdrive not installed, using wget\n'
    CONFIRM=$(
        wget -q --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate \
            "https://docs.google.com/uc?export=download&id=$FILEID" -O- |
            sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p'
    )
    trap 'rm /tmp/cookies.txt 2>/dev/null' EXIT
    [ -z "$CONFIRM" ] && { printf "Can\'t confirm: %s\n" "$1"; exit 1; }

    wget -nc --content-disposition --load-cookies /tmp/cookies.txt \
        "https://docs.google.com/uc?export=download&confirm=${CONFIRM}&id=$FILEID"
fi
