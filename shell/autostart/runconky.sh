#!/bin/sh
killall conky 2>/dev/null

conky -q -c ~/.config/conky/conky.info.conf
