#!/bin/sh
# version 2.0

sloc="$HOME/.cache/lolicorelist"
[ -f "$sloc" ] || curl -Ss https://lolicore.net/filelist.txt -o "$sloc"

quote() {
    sed '
    s/%/%25/g;
    s/ /%20/g;
    s/\[/%5B/g;
    s/\]/%5D/g;
    s/</%3C/g;
    s/>/%3E/g;
    s/#/%23/g;
    s/{/%7B/g;
    s/}/%7D/g;
    s/|/%7C/g;
    s/\\/%5C/g;
    s/\^/%5E/g;
    s/~/%7E/g;
    s/`/%60/g;
    s/\;/%3B/g;
    s/?/%3F/g;
    s/@/%40/g;
    s/=/%3D/g;
    s/&/%26/g;
    s/\$/%24/g'
}
pyquote() {
    python3 -c 'from sys import argv; print(__import__("urllib.parse").parse.quote(argv[1]))' "$1"
}

shuf -n "${n:-100}" "$sloc" | quote |
    mpv --no-config --input-ipc-server=/tmp/mpvsocket --shuffle --no-video --playlist=-
