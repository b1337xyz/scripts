#!/bin/sh
conf=~/.config/i3/config
cp -v "$conf" "${conf}.bkp" || exit 1
if grep -q '\sstatus_command' "$conf";then
    sed -i 's/\sstatus_command/ #status_command/g' "$conf"
elif grep -q '#status_command' "$conf";then
    sed -i 's/#status_command/status_command/g' "$conf"
fi
i3-msg restart >/dev/null 2>&1

exit 0
