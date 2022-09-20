#!/bin/sh

set -e

#if pgrep -x xcompmgr >/dev/null 2>&1;then 
#    pkill xcompmgr
#else
#    xcompmgr -r 4 -l -2 -t -2 -I 0.08 -O 0.4 -c -C &
#fi

if pgrep -x picom >/dev/null 2>&1;then
    pkill -9 picom
    sed -i 's/opacity: [0-9]\.[0-9]*/opacity: 1.0/' ~/.config/alacritty/alacritty.yml
    sed -i 's/i3bar/# i3bar/; s/\(set \$b0 #.\{6\}\).*/\1/' ~/.config/i3/config
else
    picom -b #--experimental-backends
    sed -i 's/opacity: [0-9]\.[0-9]*/opacity: 0.88/' ~/.config/alacritty/alacritty.yml
    sed -i 's/# i3bar/i3bar/; s/\(set \$b0 #.\{6\}\).*/\18f/' ~/.config/i3/config
fi
i3-msg restart
