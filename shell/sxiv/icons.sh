#!/usr/bin/env bash

find /usr/share/icons ~/.local/share/icons -mindepth 1 -maxdepth 1 -type d |
    dmenu -i -l 20 -c | xargs -rI{} sxiv -rt '{}'
