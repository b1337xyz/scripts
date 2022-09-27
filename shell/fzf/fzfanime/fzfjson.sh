#!/usr/bin/env bash

declare -r -x anidb=~/.cache/anilist.json
declare -r -x maldb=~/.cache/maldb.json

preview() {
    echo ">>> $anidb"
    jq -C '.["'"$1"'"]' "$anidb"
    echo ">>> $maldb"
    jq -C '.["'"$1"'"]' "$maldb"
}
export -f preview

jq -Mcr 'keys[]' "$anidb" | fzf --preview 'preview {}'
