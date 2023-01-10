#!/bin/sh

set -e

killall conky 2>/dev/null || true
nohup conky >/dev/null 2>&1 & 
nohup conky -c ~/.config/conky/conky.2.conf >/dev/null 2>&1 &
