fonts() {
    fc-list | cut -d':' -f2- | sort -u | fzf |
        tr -d \\n | sed 's/^\s*//' | xclip -sel c
}
btm() {
    find ~/.config/bottom/*.toml | fzf --layout=reverse --height 10 --print0 | xargs -0or btm -C
}
show() {
    file -Li ~/.local/bin/* | grep --color=never -oP '.*(?=:[\t ]*text/)' |
        fzf --layout=reverse --height 10 --print0 | xargs -0r bat
    echo
}
ffp() {
    find . -maxdepth 1 -type f | fzf --preview-window "right:60%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}'
}
e() {
    find ~/.scripts ~/.local/share/qutebrowser/{js,userscripts} -type f -size -100k \
        \! \( -name '__*__' -o -iregex '.*\.\(png\|jpg\)' \)  |
        awk -v home="$HOME" 'sub(home, "~")' |
        fzf -e --layout=reverse --height 20  |
        awk -v home="$HOME" 'sub("~", home)' | xargs -roI{} vim '{}'
}
c() { 
    find ~/.config -maxdepth 4 -type f -size -100k \
        \! \( -name '__*__' -o -iregex '.*\.\(bdic\|tdb\|lpl\|spl\|state[0-9]?\|srm\|png\|jpg\|auto\)' \) |
        awk -v home="$HOME" 'sub(home, "~")' | 
        fzf -e --layout=reverse --height 20  |
        awk -v home="$HOME" 'sub("~", home)' | xargs -roI{} vim '{}'
}
fzfumount() {
    local dev
    dev=$(command df -x tmpfs -x devtmpfs | tail -n +2 | sort -Vr |
        awk '!/sda/{printf("%-20s %s\n", $1, $6)}' | fzf --layout=reverse --height 10 | awk '{print $1}')
    [ -n "$dev" ] && sudo umount "$dev"
    sleep .5; df -h -t ext4 -t btrfs --total
}
ftorrent() {
    local torrent
    find ~/.cache/torrents -iname '*.torrent' -printf '%f\n' |
    fzf --layout=reverse --height 10 -m | while read -r torrent
    do
        torrent=${torrent//\[/\\[}  torrent=${torrent//\]/\\]}
        torrent=${torrent//\*/\\*}  torrent=${torrent//\$/\\$}
        torrent=${torrent//\?/\\?}   
        find ~/.cache/torrents -type f -name "$torrent"
    done
}
cptorrent() { ftorrent | xargs -rI{} cp -v '{}' . ;}
cdanime() {
    pv() {
        p=$(readlink -m ~/Videos/Anime/"$1")
        printf '%s ' "$p"
        [ -e "$p" ] || printf '(\e[1;31mUnavailable\e[m)\n'
    }
    export -f pv
    out=$(
        find ~/Videos/Anime -mindepth 1 -maxdepth 1 -printf '%f\n' |
        sort | fzf -e --no-sort --preview-window 'bottom:10%' --preview 'pv {}'
    )
    unset pv
    cd ~/Videos/Anime/"$out" || return 1
}
btf() {
    aria2c -S ~/.cache/torrents/*/*.torrent         |
    awk -F'|' '/[0-9]\|\.\//{print $2}' | fzf $@    |
    awk -F'/' '{print $2}' |
    sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0        |
    xargs -0rI{} find ~/.cache/torrents -type f -name '{}.torrent'
}
fzfbt() {
    pv() {
        aria2c -S "$1" # | sed '/^idx\|path\/length/q'
    }
    export -f pv 
    find . -maxdepth 1 -iname '*.torrent' | fzf \
        --preview 'pv {}' --preview-window 'border-sharp'
    unset pv
}
alacritty_theme_switcher() {
    declare -r -x config=~/.config/alacritty/alacritty.yml
    declare -r -x themes=~/.config/alacritty/themes
    cp -v "$config" "${config}.bkp"
    function pv {
        sed -i "s/\/themes\/.*\.yml$/\/themes\/${1}/" "$config"
        bat --style=numbers --color=always --line-range :15 ~/.bashrc
        ls -x --color=always ~/
        bash ~/.scripts/playground/shell/Colors/panes
        bash ~/.scripts/playground/shell/Colors/spectrum
        bash ~/.scripts/playground/shell/Colors/bars
    }
    export -f pv
    find "$themes" -type f -printf '%f\n' | sort |
        fzf -e --preview-window "border-none:right:60%" --preview 'pv {}'
    unset pv

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
        fzf --height 20 -e -m --bind 'ctrl-d:execute(dl {+})')
    unset dl
}
fzfopen() {
    fzf --bind 'enter:execute-silent(xdg-open {} & disown)'
}
