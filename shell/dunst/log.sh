#!/bin/sh
log=~/.cache/dunst.json
[ -s "$log" ] || echo "[]" > "$log"
jq -Mc --arg title "$2" --arg summary "$3" --arg icon "$4" --arg urgency "$5" \
    --arg time "$(date +'%Y-%m-%d %H:%M')" \
    '. + [{$title, $summary, $icon, $urgency, $time}]' "$log" > "${log}.bak"

cp "${log}.bak" "$log"

exit 0
