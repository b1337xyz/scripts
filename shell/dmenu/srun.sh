#!/bin/sh
set -e

cd ~/.local/share/applications
grep -rn 'Exec=steam' | grep -oP '.*(?=\.desktop:)' | sort -V | dmenu -i -c -l 10 | while read -r file
do
    file=${file}.desktop
    if [ -f "$file" ];then
        notify-send "Executing..." "$file"
        exec=$(grep -oP '(?<=Exec=).*' "$file")
        i3-msg "exec --no-startup-id $exec"
    fi
    break
done