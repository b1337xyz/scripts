#!/bin/sh
# shellcheck disable=SC2091

# set -e

menu() { cat << EOF
Run conky
Kill conky
Close
EOF
}

opt=$(menu | fzf --disabled --cycle --border=none --reverse --no-info --no-separator --prompt="> fzmenu < ")
case "$opt" in
    Kill?conky) killall conky ;;
    Run?conky) i3-msg 'exec --no-startup-id runconky.sh' ;;
esac >/dev/null 2>&1
