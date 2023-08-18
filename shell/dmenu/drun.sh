#!/bin/sh
# shellcheck disable=SC2091
# shellcheck disable=SC2068
set -e

progs=~/.cache/programs
tmpfile=$(mktemp)
trap 'rm "$tmpfile"' EXIT

run() {
    # $( $@ >/dev/null 2>&1 &)
    # nohup $@ >/dev/null 2>&1 &
    # setsid -f -- $@ >/dev/null 2>&1
    i3-msg exec "$*" 2>&1 &
}

# clean up
cp "$progs" "$tmpfile"
while read -r i;do
    command -v "$i" >/dev/null 2>&1 ||
        sed -i "/${i}/d" "$progs"
done < "$tmpfile"

cmd=$(sort -u "$progs" | dmenu -p 'run:' -i -c -l 10)
[ -z "$cmd" ] && exit 1
grep -q "$cmd" "$progs" || echo "$cmd" >> "$progs"
case "$cmd" in
    pulsemixer|top) run ts -n floating_terminal -- "$cmd" ;;
    sxcs)           run 'sxcs | xclip -sel c' ;;
    cmus)           run ts -t cmus -- tmux attach -t cmus ;; 
    ncmpcpp)        run ts -t ncmpcpp -- ncmpcpp ;; 
    newsboat)       run ts -n newsboat -t newsboat -- newsboat ;;
    spotify)        run spotify -no-zygote ;;
    conky)          runconky.sh ;;
    fzfanime.sh)    run ts -- fzfanime.sh ;;
    cava)           run st -n Cava -g 40x10+15-15 cava ;;
    *) run "$cmd" ;;
esac
