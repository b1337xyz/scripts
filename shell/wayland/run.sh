#!/bin/sh
# shellcheck disable=SC2091
# shellcheck disable=SC2068
set -e

progs=~/.cache/programs
tmpfile=$(mktemp)
trap 'rm "$tmpfile"' EXIT

run() {
    desktop_file=$(grep -rxF "Name=${*}" ~/.local/share/applications | cut -d':' -f1)
    if [ -f "$desktop_file" ]; then
        touch "$desktop_file"
        cmd=$(grep -oP '(?<=^Exec=).*' "$desktop_file")
        set -- "$cmd"
    fi

    if hash swaymsg;then
        swaymsg exec "$*" >/dev/null 2>&1
    else
        nohup $@ >/dev/null 2>&1 &
    fi
}

# clean up
cp "$progs" "$tmpfile"
while read -r i;do
    command -v "$i" >/dev/null 2>&1 ||
        sed -i "/${i}/d" "$progs"
done < "$tmpfile"

choice=$(printf 'Apps\nGames\n' | rofi -dmenu -i -l 10)

case "$choice" in 
    Games)
        find ~/.local/share/applications -name '*.desktop' -printf '%C@\t%p\n' |
            sort -rn| cut -f2- | tr \\n \\0 | xargs -0r grep Categories=Game |
            while IFS=: read -r i _;do
                grep -oP '(?<=^Name=).*' "$i"
            done > "$tmpfile"
    ;;
esac

cmd=$(rofi -dmenu -p 'run' -i -l 10 < "$tmpfile")
[ -z "$cmd" ] && exit 1
grep -qxF "$cmd" "$tmpfile" || echo "$cmd" >> "$progs"
case "$cmd" in
    pulsemixer|top) run "$TERMINAL" --class floating_window -e "$cmd" ;;
    ncmpcpp)        run "$TERMINAL" --title ncmpcpp -e ncmpcpp ;; 
    newsboat)       run "$TERMINAL" --class newsboat --title newsboat -e newsboat ;;
    fzfanime.sh)    run "$TERMINAL" --title fzfanime -e fzfanime.sh ;;
    cmus)           run tmux new-session -d -s cmus cmus ;; 
    spotify)        run spotify -no-zygote ;;
    *rpcs3*)        run gamemoderun "$cmd" ;;
    dhewm3) 
        run dhewm3 +set fs_basepath "${HOME}/.local/share/Steam/steamapps/common/Doom 3" ;;
    *) [ -n "$cmd" ] && run "$cmd" ;;
esac
