txt() {
    target=$(find ~/Documents/txt -type f | sort | fzf)
    [ -f "$target" ] || return 1
    vim "$target"
}
fonts() {
    fc-list | cut -d':' -f2- | sort | uniq | fzf |
        tr -d \\n | sed 's/^\s*//' | xclip -sel clip
}
ffp() {
    find . -maxdepth 1 -type f | fzf --preview-window "right:60%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}'
}
fz() {
    local target
    target=$(find ~/.scripts -executable -type f | fzf)
    case $1 in
        e) $EDITOR "$target" ;;
        *) less "$target" ;;
    esac
}
e() {
    local target f fpath
    target=~/.scripts
    f=$(find "$target" -type f \( -regex '.*\.\(py\|sh\)' -o -iname '*_functions' \) \
        \! -regex '.*\(log\|__.*__\|/venv/\).*' 2>/dev/null |
        sed 's/^'"${target//\//\\\/}"'\///' | fzf)
    #cd "${target}/${f%/*}" || return 1
    fpath="${target}/${f}"
    [ -f "$fpath" ] && vim "$fpath"
}
conf() { 
    exp='themes\|discord\|chromium\|pulse\|playlists\|watch_later'
    exp="${exp}\|__.*__\|retroarch\|jellyfin"
    fp=$(find ~/.config ~/.vim -type f \
        ! -regex ".*/\(${exp}\)/.*" | fzf -e)
    [ -f "$fp" ] && vim "$fp"
}
cconf() {
    fpath=$(fzf << EOF
.vim/vimrc
.bashrc
.xinitrc
.profile
.config/X11/Xresources
.config/cava/config
.config/bash_aliases
.config/kitty/kitty.conf
.config/ranger/rc.conf
.config/ranger/rifle.conf
.config/ranger/scope.sh
.config/i3/config
.config/i3/i3blocks.conf
.config/i3/i3blocks_bot.conf
.config/mpv/mpv.conf
.config/mpv/input.conf
.config/sxhkd/sxhkdrc
.config/conky/conky.conf
.config/alacritty/alacritty.yml
.config/qutebrowser/config.py
.config/qutebrowser/quickmarks
.config/qutebrowser/custom.py
.config/newsboat/config
.config/newsboat/urls
.config/lf/lfrc
.config/aria2/aria2.conf
.config/dunst/dunstrc
EOF
    )
    [ -f "$fpath" ] && vim ~/"$fpath"
}
fzfumount() {
    local dev
    dev=$(command df -x tmpfs -x devtmpfs | tail -n +2 | sort |
        awk '!/sda/{printf("%-20s %s\n", $1, $6)}' | fzf | awk '{print $1}')
    [ -z "$dev" ] && return 1
    udisksctl unmount -b "$dev"
}
fzcd() {
    out=$(find -L . -mindepth 1 -type d |
        fzf --preview 'ls -1 --color=always {}' --preview-window 'right:50%')
    [ -z "$out" ] && return 1
    cd "$out" || return 1
}
ftorrent() {
    local torrent
    torrent=$(find ~/.cache/torrents -iname '*.torrent' -printf '%f\n' | fzf)
    torrent=${torrent//\[/\\[}  torrent=${torrent//\]/\\]}
    torrent=${torrent//\*/\\*}  torrent=${torrent//\$/\\$}
    torrent=${torrent//\?/\\?}   
    find ~/.cache/torrents -type f -name "$torrent"
}
cptorrent() {
    local torrent
    torrent=$(ftorrent)
    [ -f "$torrent" ] && cp -v "$torrent" .
}
cdanime() {
    preview() {
        p=$(readlink -m ~/Videos/Anime/"$1")
        printf '%s ' "$p"
        [ -e "$p" ] || printf '(\e[1;31mUnavailable\e[m)\n'
    }
    export -f preview
    out=$(
        find ~/Videos/Anime -mindepth 1 -maxdepth 1 -printf '%f\n' |
        sort | fzf -e --no-sort --preview-window 'bottom:10%' --preview 'preview {}'
    )
    cd ~/Videos/Anime/"$out" || return 1
}
btf() {
    local file

    # shellcheck disable=SC2068
    file=$(aria2c -S ~/.cache/torrents/*/*.torrent | awk -F'|' '/[0-9]\|\.\//{print $2}' | fzf $@)
    [ -z "$file" ] && return 1

    ptr=${file#*/} ptr=${ptr%%/*}
    ptr=${ptr//\[/\\[}  ptr=${ptr//\]/\\]}
    ptr=${ptr//\*/\\*}  ptr=${ptr//\?/\\?}   
    torrent_file=$(find ~/.cache/torrents -name "${ptr}.torrent")
    if [ -n "$torrent_file" ];then
        printf '%s\n' "$torrent_file"
    else
        find ~/.cache/torrents -iname '*.torrent' | while read -r i;do
            if aria2c -S "$i" | grep -qoF "$file";then
                printf '%s\n' "$i"
                break
            fi
        done
    fi
}
fzfbt() {
    preview() {
        aria2c -S "$1" | sed '/^idx\|path\/length/q'
    }
    export -f preview

    find . -maxdepth 1 -iname '*.torrent' | fzf \
        --preview 'preview {}' --preview-window 'border-sharp'
}
alacritty_theme_switcher() {
    declare -r -x config=~/.config/alacritty/alacritty.yml
    declare -r -x themes=~/.config/alacritty/themes

    cp -v "$config" "${config}.bkp"

    function pv {
        sed -i "s/\/themes\/.*\.yml$/\/themes\/${1}/" "$config"
        bat --style=numbers --color=always --line-range :20 ~/.bashrc
        ls -x --color=always ~/
    }
    export -f pv

    find "$themes" -type f -printf '%f\n' | sort |
        fzf -e --preview-window "border-none:right:60%" --preview 'pv {}'

    read -r -p 'Undo? (y/n) ' ask
    [ "${ask,,}" = "y" ] && cp -v "${config}.bkp" "$config"

    return 0
}
dlbkp() {
    local target
    target=${1:-.}

    dl() {
        for i in "$@";do
            rclone copy -P gdrive:backups/"$i" "$target"
        done
    }
    export -f dl

    while read -r i;do
        [ -n "$i" ] && dl "$i" 
    done < <(rclone lsf gdrive:backups |
        fzf -e -m --bind 'ctrl-d:execute(dl {+})')
}
