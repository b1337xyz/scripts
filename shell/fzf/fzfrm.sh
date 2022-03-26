#!/usr/bin/env bash

function fzf_preview {
    if [ -f "$1" ];then
        mimetype=$(file -Lbi -- "$1")
        case "$mimetype" in
            audio/*|video/*|image/*) mediainfo "$1" ;;
            text/*) bat --style=numbers --color=always --line-range :500 "$1" ;;
            *x-rar*) unrar vt "$1" ;;
        esac
    elif [ -d "$1" ];then
        exa -l --color=always "$1" 
    fi
}
export -f fzf_preview

find . -mindepth 1 -maxdepth 1 | sort -Vr |
    fzf -m --preview 'fzf_preview {}' --preview-window "right:65%" --print0 | xargs -r0 rm -v

