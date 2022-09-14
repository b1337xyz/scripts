#!/usr/bin/env bash

set -eo pipefail

find ~/.local/src/scripts -mindepth 2 -type f | while read -r old
do
    new=${old/local\/src\//}
    [ -e "$new" ] || continue
    diff --color=always "$old" "$new" || cp -vi "$new" "$old" </dev/tty
done
