#!/bin/sh
set -e

cd ~/.local/share/applications
grep -rn 'Exec=steam' | while read -r i; do
    grep -oP '(?<=Name=).*' "${i%%:*}"
done | dmenu -i -c -l 10 | while read -r name; do
    file=$(grep -rnF "Name=$name" | cut -d':' -f1)
    if [ -f "$file" ];then
        notify-send "Executing..." "$name"
        exec=$(grep -oP '(?<=Exec=).*' "$file")
        i3-msg "exec --no-startup-id $exec"
    fi
    break
done
