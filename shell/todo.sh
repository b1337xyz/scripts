#!/usr/bin/env bash

TODOFILE=~/Documents/.todo

set -e

usage() {
    printf 'Usage: %s [help ed ls add rm] <TODO>\n' "${0##*/}"
    exit "${1:-0}"
}

case "$1" in
    help) usage ;;
    ed) [ -s "$TODOFILE" ] && vim "$TODOFILE" ;;
    ls)
        l=$(wc -c < "$TODOFILE")
        [ "$l" -lt 3 ] && exit 0
        printf '\e[0;30;43mTODO\e[m\n'
        while IFS='|' read -r added str;do
            printf '%s: %s\n' "$added" "$str"
        done < "$TODOFILE"
    ;;
    add)
        shift
        [ -n "$1" ] && printf '%s|%s\n' "$(date +%d-%m-%Y' '%H:%M)" "$*" >> "$TODOFILE"
    ;;
    rm)
        [ -s "$TODOFILE" ] || exit 1
        awk -F'|' '{printf("\033[1;31m%s\033[m: %s - %s\n", NR, $1, $2)}' "$TODOFILE"
        read -r -p ": " ask
        [ -z "$ask" ] && exit 0
        l=$(wc -l < "$TODOFILE")
        [[ "$ask" =~ ^[0-9]*$ ]] || exit 1
        [ "$ask" -gt "$l" ] || [ "$ask" -lt 1 ] && exit 1
        sed -i "${ask}d" "$TODOFILE"
    ;;
    *) usage 1 ;;
esac
