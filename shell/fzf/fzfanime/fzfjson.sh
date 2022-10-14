#!/usr/bin/env bash

declare -r -x anidb=~/.scripts/python/myanimedb/anilist.json
declare -r -x maldb=~/.scripts/python/myanimedb/maldb.json

preview() {
    echo ">>> $anidb"
    jq -C --arg k "$1" '.[$k]' "$anidb"
    echo ">>> $maldb"
    jq -C --arg k "$1" '.[$k]' "$maldb"
}
export -f preview

jq -Mcr 'keys[]' "$anidb" | fzf --preview 'preview {}'
