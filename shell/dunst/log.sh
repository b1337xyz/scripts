#!/bin/sh
set -e
log=~/.cache/dunst.json
[ -s "$log" ] || echo "[]" > "$log"
jq -Mc --arg title "$2" --arg summary "$3" --arg icon "$4" --arg urgency "$5" \
    '.[-99:] + [{$title, $summary, $icon, $urgency}]' "$log" > "${log}.bak"

cp "${log}.bak" "$log"
