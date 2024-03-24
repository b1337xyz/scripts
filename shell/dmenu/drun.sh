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
grep -qxF "$cmd" "$progs" || echo "$cmd" >> "$progs"
case "$cmd" in
    pulsemixer|top) run "$TERMINAL" --class floating_window -e "$cmd" ;;
    ncmpcpp)        run "$TERMINAL" --title ncmpcpp -e ncmpcpp ;; 
    newsboat)       run "$TERMINAL" --class newsboat --title newsboat -e newsboat ;;
    fzfanime.sh)    run "$TERMINAL" --title fzfanime -e fzfanime.sh ;;
    cmus)           run tmux new-session -d -s cmus cmus ;; 
    spotify)        run spotify -no-zygote ;;
    conky)          runconky.sh ;;
    dhewm3) 
        # shellcheck disable=SC2016
        run 'dhewm3 +set fs_basepath "${HOME}/.local/share/Steam/steamapps/common/Doom 3"'
        ;;
    *) run "$cmd" ;;
esac
