#!/bin/sh
# shellcheck disable=SC2091

# set -e

menu() { cat << EOF
Kill conky
Close
EOF
}

opt=$(menu | fzf --disabled --border=none --reverse --no-info --no-separator --prompt="> fzmenu < ")
case "$opt" in
    Kill?conky) killall conky ;;
esac >/dev/null 2>&1
