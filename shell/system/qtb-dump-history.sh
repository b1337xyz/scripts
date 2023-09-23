#!/usr/bin/env bash
sqlite3 -separator $'\t' ~/.local/share/qutebrowser/history.sqlite \
    'SELECT atime, url FROM History;' | awk 'seen[$1]++' > ~/qtb-history
