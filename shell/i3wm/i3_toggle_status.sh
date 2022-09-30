#!/bin/sh
conf=~/.config/i3/config
if grep -q ' status_command' "$conf" ;then
    sed -i 's/ status_command/ #status_command/g' "$conf"
elif grep -q '#status_command' "$conf" ;then
    sed -i 's/#status_command/status_command/g' "$conf"
fi
i3-msg restart >/dev/null 2>&1
