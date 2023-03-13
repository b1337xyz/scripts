#!/bin/sh
# shellcheck disable=SC2091
# shellcheck disable=SC2068
set -e

programs=~/.cache/programs
tmpfile=$(mktemp)
trap 'rm "$tmpfile"' EXIT

run() {
    $( $@ >/dev/null 2>&1 &)
    # nohup $@ >/dev/null 2>&1 &
    # setsid -f -- $@ >/dev/null 2>&1
}

# clean up
cp "$programs" "$tmpfile"
while read -r i;do
    command -v "$i" >/dev/null 2>&1 ||
        sed -i "/${i}/d" "$programs"
done < "$tmpfile"

cmd=$(sort -u "$programs" | dmenu -p 'run:' -i -c -l 10)
[ -z "$cmd" ] && exit 1
case "$cmd" in
    pulsemixer|top) run ts -n floating_terminal -- "$cmd" ;;
    cmus)           run ts -n cmus -t cmus -- cmus.sh ;; 
    ncmpcpp)        run ts -n ncmpcpp -t ncmpcpp -- ncmpcpp ;; 
    newsboat)       run ts -n newsboat -t newsboat -- newsboat ;;
    spotify)        run spotify -no-zygote ;;
    conky)          runconky.sh ;;
    *) run "$cmd" ;;
esac
