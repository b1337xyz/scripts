#!/usr/bin/env bash
set -eo pipefail

case "$1" in
    [1-9]) FIND="find -L . -mindepth 1 -maxdepth $1 -print0" ;;
    -m)    FIND='find -L . -mindepth 1 -type f -print0'     ;;
    *)     FIND='find -L . -mindepth 1 -maxdepth 1 -print0' ;;
esac

declare -a files=()
while IFS= read -r -d $'\0' i;do
    files+=("${i#*/}")
done < <($FIND | sort -zV) # -t / -k 3

[ "${#files[@]}" -eq 0 ] && { printf 'Nothing to do\n'; exit 0; }

tmpfile=$(mktemp)
trap 'rm "$tmpfile"' EXIT
printf '%s\n' "${files[@]}" >> "$tmpfile"
vim "$tmpfile"

l=$(wc -l < "$tmpfile")
[ "${#files[@]}" -ne "$l" ] && { printf 'Number of lines mismatch.\n'; exit 1; }

i=0
while read -r f;do
    [ "${files[i]}" != "$f" ] && { mv -vn -- "${files[i]}" "$f" || continue; }
    i=$((i+1))
done < "$tmpfile"
