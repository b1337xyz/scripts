#!/bin/sh
killall conky 2>/dev/null
nohup conky >/dev/null 2>&1 & 
nohup conky -c ~/.config/conky/conky.2.conf >/dev/null 2>&1 &
