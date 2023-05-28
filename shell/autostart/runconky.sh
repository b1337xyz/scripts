#!/bin/sh
killall conky 2>/dev/null

conky -q -c ~/.config/conky/conky.clock.conf
conky -q -c ~/.config/conky/conky.bat.conf
conky -q -c ~/.config/conky/conky.info.conf
