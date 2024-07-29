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

    desktop_file=$(grep -rxF "Name=${*}" ~/.local/share/applications | cut -d':' -f1)
    if [ -f "$desktop_file" ]; then
        cmd=$(grep -oP '(?<=^Exec=).*' "$desktop_file")
        set -- "$cmd"
    fi
    i3-msg exec "$*" 2>&1 &
}

# clean up
cp "$progs" "$tmpfile"
while read -r i;do
    command -v "$i" >/dev/null 2>&1 ||
        sed -i "/${i}/d" "$progs"
done < "$tmpfile"

grep -r 'Categories=Game' ~/.local/share/applications | while IFS=: read -r i _;do
    grep -oP '(?<=^Name=).*' "$i"
done >> "$progs"

cmd=$(sort -Vu "$progs" | dmenu -p 'run:' -i -c -l 10)
[ -z "$cmd" ] && exit 1
grep -qxF "$cmd" "$progs" || echo "$cmd" >> "$progs"
case "$cmd" in
    pulsemixer|top) run "$TERMINAL" --class floating_window -e "$cmd" ;;
    ncmpcpp)        run "$TERMINAL" --title ncmpcpp -e ncmpcpp ;; 
    newsboat)       run "$TERMINAL" --class newsboat --title newsboat -e newsboat ;;
    fzfanime.sh)    run "$TERMINAL" --title fzfanime -e fzfanime.sh ;;
    cmus)           run tmux new-session -d -s cmus cmus ;; 
    spotify)        run spotify -no-zygote ;;
    dhewm3) 
        run dhewm3 +set fs_basepath "${HOME}/.local/share/Steam/steamapps/common/Doom 3"
        ;;
    *) [ -n "$cmd" ] && run "$cmd" ;;
esac
