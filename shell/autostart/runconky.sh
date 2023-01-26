#!/usr/bin/env bash
killall conky 2>/dev/null
conky -q -d
conky -q -d -c ~/.config/conky/conky.disk.conf
