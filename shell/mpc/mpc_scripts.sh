#!/usr/bin/env bash
command -v dmenu &>/dev/null || { printf 'install dmenu\n'; exit 1; }
scripts='/home/erik/.scripts/ShellScript/mpc_scripts'
for i in "$scripts"/*.sh;do
    [ "${i##*/}" = "${0##*/}" ] && continue
    basename "$i"
done | dmenu -l 15 -p 'mpc_scripts:' | xargs -rI{} bash "$scripts/{}"
