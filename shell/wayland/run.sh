#!/bin/sh
# shellcheck disable=SC2091
# shellcheck disable=SC2068
# shellcheck disable=SC2016
set -e

progs=~/.cache/programs
tmpfile=$(mktemp)
trap 'rm "$tmpfile"' EXIT

run() {
    # $( $@ >/dev/null 2>&1 &)
    # nohup $@ >/dev/null 2>&1 &
    # setsid -f -- $@ >/dev/null 2>&1
    swaymsg exec "$*" >/dev/null 2>&1
}

# clean up
cp "$progs" "$tmpfile"
while read -r i;do
    command -v "$i" >/dev/null 2>&1 ||
        sed -i "/${i}/d" "$progs"
done < "$tmpfile"

cmd=$(sort -u "$progs" | rofi -dmenu -p 'run' -i -l 10)
[ -z "$cmd" ] && exit 1
grep -qxF "$cmd" "$progs" || echo "$cmd" >> "$progs"
case "$cmd" in
    cmus) run tmux new-session -d -s cmus cmus ;; 
    spotify) run spotify -no-zygote ;;
    conky) runconky.sh ;;
    dolphin-emu) run 'QT_QPA_PLATFORM=xcb dolphin-emu' ;;
    dhewm3) 
        run 'dhewm3 +set fs_basepath "${HOME}/.local/share/Steam/steamapps/common/Doom 3"'
        ;;
    *) run "$cmd" ;;
esac
