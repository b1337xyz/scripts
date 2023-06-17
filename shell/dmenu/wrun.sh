#!/bin/sh
set -e

cd ~/Desktop
grep -rn 'Exec=env WINE' | grep -oP '.*(?=\.desktop:)' | sort -V | dmenu -i -c -l 10 | while read -r file
do
    file=${file}.desktop
    if [ -f "$file" ];then
        notify-send "Executing..." "$file"
        exec=$(grep -oP '(?<=Exec=).*' "$file")
        i3-msg "exec --no-startup-id $exec"
    fi
    break
done
