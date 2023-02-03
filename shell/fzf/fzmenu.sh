#!/bin/sh
# shellcheck disable=SC2091

# set -e

menu() { cat << EOF
Run conky
Run fzfanime
Kill conky
Close
EOF
}
run() {
    i3-msg "exec --no-startup-id $*"
}

opt=$(menu | fzf --disabled --cycle --border=none --reverse --no-info --no-separator --prompt="> fzmenu < ")
case "$opt" in
    Kill?conky) killall conky ;;
    Run?conky) run runconky.sh  ;;
    Run?fzfanime) run ts -- fzfanime.sh ;;
esac >/dev/null 2>&1
