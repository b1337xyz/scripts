#!/bin/sh
# shellcheck disable=SC2091

# set -e

menu() { cat << EOF
close
conky
fzfanime
qutebrowser
firefox
chromium
qbittorrent
alacritty
kill conky
EOF
}
run() {
    i3-msg "exec --no-startup-id $*"
}

opt=$(menu | fzf --cycle --border=none --no-info --no-separator --prompt="run: ")
case "$opt" in
    kill?conky) killall conky ;;
    conky) run runconky.sh  ;;
    fzfanime) run ts -- fzfanime.sh ;;
    *) run "$opt" ;;
esac >/dev/null 2>&1
