#!/usr/bin/env bash
set -eo pipefail

declare -A scratchpad=()
while IFS=: read -r pid name ;do
    [ "$pid" = "null" ] && continue
    scratchpad[$name]=$pid
done < <(swaymsg -t get_tree | jq -Mcr '.. | .floating_nodes? // empty | .. | "\(.pid?):\(.name?)"')
[ "${#scratchpad[@]}" -eq 0 ] && exit 0
if [ "${#scratchpad[@]}" -gt 1 ];then
    name=$(printf '%s\n' "${!scratchpad[@]}" | rofi -dmenu -l 10 -c)
    pid=${scratchpad["$name"]}
    swaymsg "[pid=${pid}]" focus
else
    swaymsg scratchpad show
fi
swaymsg floating toggle
