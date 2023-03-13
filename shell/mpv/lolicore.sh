#!/bin/sh

set -eo pipefail

sloc="$HOME/.cache/lolicorelist"
[ -f "$sloc" ] || curl -Ss https://archive.lolicore.net/filelist.txt -o "$sloc"

unquote() {
    python3 -c '
from sys import stdin, stdout
from urllib.parse import unquote
for i in stdin:
    stdout.write(unquote(i.strip()) + "\n")'
}

shuf -n "${n:-100}" "$sloc" | unquote |
    mpv --no-config --input-ipc-server=/tmp/mpvradio --shuffle --no-video --playlist=-
