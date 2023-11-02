#!/bin/sh
set -e

cd ~/.local/share/applications
grep -rn 'Exec=steam' | grep -oP '.*(?=\.desktop:)' |
    grep -v -e Proton -e 'Steam Linux' |
    sort -Vu | dmenu -i -c -l 25 | while read -r file
do
    file=${file}.desktop
    if [ -f "$file" ];then
        notify-send "Executing..." "$file"
        exec=$(grep -oP '(?<=Exec=).*' "$file")
        i3-msg "exec --no-startup-id $exec"
    fi
    break
done
