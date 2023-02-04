#!/bin/sh
set -e

cd ~/.local/share/applications
grep -rn 'Exec=steam' | cut -d':' -f1 | while read -r i;do
    grep -oP '(?<=Name=).*' "$i"
done | dmenu -c -l 10 | while read -r i;do
    file=$(grep -rnF "Name=$i" | cut -d':' -f1)
    if [ -f "$file" ];then
        exec=$(grep -oP '(?<=Exec=).*' "$file")
        i3-msg "exec --no-startup-id $exec"
    fi
    break
done
