#!/usr/bin/env bash

set -eo pipefail

f=~/.cache/emoticons.json
if [ "$1" = "dmenu" ];then
    jq -Mcr 'keys[] as $k |"\($k) \(.[$k])"' "$f" | shuf | dmenu -i -l 30
else
    jq -Mcr 'keys[] as $k |"\($k) \(.[$k])"' "$f" | shuf | fzf --height 30
fi | cut -d' ' -f1 | xargs -rI{} jq -Mcr '.["{}"]' "$f" | tr -d \\n #| xclip -sel clip
