#!/bin/sh
# shellcheck disable=SC2016

set -e

# if pgrep -x xcompmgr >/dev/null 2>&1;then 
#     pkill xcompmgr
# else
#     xcompmgr -r 4 -l -2 -t -2 -I 0.08 -O 0.4 -c -C &
# fi

# i3_theme=~/.config/i3/$(grep -oP '(?<=include )themes/.*' ~/.config/i3/config)
if pgrep -x picom >/dev/null 2>&1; then
    pkill -9 picom
    sed -i 's/opacity: [0-9\.]\+/opacity: 1.0/' ~/.config/alacritty/alacritty.yml
    # sed -i 's/\(^\s\+\)i3bar/\1# i3bar/; s/\(set \$bbg #.\{6\}\).*/\1/' "$i3_theme"
    # sed -i 's/\(own_window_argb_visual =\) true/\1 false/' ~/.config/conky/conky.conf ~/.config/conky/conky.disk.conf
        
else
    picom -b # --experimental-backends
    sed -i 's/opacity: [0-9\.]\+/opacity: 0.8/' ~/.config/alacritty/alacritty.yml
    # sed -i 's/\(^\s\+\) # i3bar/\1 i3bar/; s/\(set \$bbg #.\{6\}\).*/\100/' "$i3_theme"
    # sed -i 's/\(own_window_argb_visual =\) false/\1 true/' ~/.config/conky/conky.conf ~/.config/conky/conky.disk.conf
fi
# i3-msg restart
