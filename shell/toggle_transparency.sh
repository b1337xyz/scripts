#!/bin/sh
# shellcheck disable=SC2016

set -e

# if pgrep -x xcompmgr >/dev/null 2>&1;then 
#     pkill xcompmgr
# else
#     xcompmgr -r 4 -l -2 -t -2 -I 0.08 -O 0.4 -c -C &
# fi

if pgrep -x picom >/dev/null 2>&1; then
    pkill -9 picom
    sed -i 's/opacity: [0-9]\.[0-9]*/opacity: 1.0/' ~/.config/alacritty/alacritty.yml
    sed -i 's/\(^\s\+\)i3bar/\1# i3bar/; s/\(set \$b0 #.\{6\}\).*/\1/' ~/.config/i3/theme
    sed -i 's/\(^\s\+\)own_window_argb/\1-- own_window_argb/g' \
        ~/.config/conky/conky.conf ~/.config/conky/conky.2.conf
else
    picom -b  # --experimental-backends
    sed -i 's/opacity: [0-9]\.[0-9]*/opacity: 0.80/' ~/.config/alacritty/alacritty.yml
    sed -i 's/\(^\s\+\) # i3bar/\1 i3bar/; s/\(set \$b0 #.\{6\}\).*/\18f/' ~/.config/i3/theme
    sed -i 's/\(^\s\+\) -- own_window_argb/\1 own_window_argb/g' \
        ~/.config/conky/conky.conf ~/.config/conky/conky.2.conf
fi
i3-msg restart
