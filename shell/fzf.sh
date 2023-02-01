fonts() {
    fc-list | cut -d':' -f2- | sort -u | fzf |
        tr -d \\n | sed 's/^\s*//' | xclip -sel c
}
fzbtm() {
    find ~/.config/bottom/*.toml | fzf --layout=reverse \
        --height 10 --print0 | xargs -0or btm -C
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
    local file
    file=$(find ~/.scripts ~/.local/share/qutebrowser/{js,userscripts} \
        -type f -size -100k -regextype posix-extended \
        \! \( -path '*__*__*' -o -path '*/venv/*' -o -iregex '.*\.(png|jpg|json)' \) |
        awk -v home="$HOME" 'sub(home, "~")' |
        fzf -e --layout=reverse --height 20  |
        awk -v home="$HOME" 'sub("~", home)')

    if [ -f "$file" ]; then
        cd "${file%/*}" || return 1
        vim "$file"
    fi
}
c() { 
    local file
    file=$(find ~/.config -maxdepth 3 -type f -size -100k -regextype posix-extended \
        \! \( -name '__*__' -o -iregex \
        '.*\.(bdic|tdb|lpl|spl|state[0-9]?|srm|png|jpg|auto|crt|pem|lock)' \) |
        awk -v home="$HOME" 'sub(home, "~")' | 
        fzf -e --layout=reverse --height 20  |
        awk -v home="$HOME" 'sub("~", home)')

    if [ -f "$file" ];then 
        cd "${file%/*}" || return 1
        vim "$file"
    fi
}
fzumount() {
    command df -x tmpfs -x devtmpfs | tail -n +2 | sort -Vr |
        awk '!/sda|nvme/{printf("%-20s %s\n", $1, $6)}' |
        fzf -m --layout=reverse --height 10 | awk '{print $1}' |
        xargs -roI{} sudo umount '{}' && sleep 1 &&
        command df -h -x tmpfs -x devtmpfs | grep -vP '/dev/sda|nvme'
}
fztorrent() {
    find ~/.cache/torrents -iname '*.torrent' -printf '%f\n' | sort -V |
    fzf --layout=reverse --height 20 -m | sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 |
        xargs -0rI{} find ~/.cache/torrents -type f -name '{}'
}
cptorrent() { fztorrent | tr \\n \\0 | xargs -0rI{} cp -v '{}' . ;}
cdanime() {
    out=$(
        find ~/Videos/Anime -mindepth 1 -maxdepth 1 \! -xtype l -printf '%f\n' |
        sort -V | fzf -e --no-sort --preview-window 'bottom:10%' \
                --preview 'readlink -m ~/Videos/Anime/{}'
    )
    cd ~/Videos/Anime/"$out" || return 1
}
fzcbt() {
    local cache
    cache=~/.cache/torrents/torrents.txt
    if [ -f "$cache" ];then
        cat "$cache"
    else
        aria2c -S ~/.cache/torrents/*/*.torrent |
            awk -F'|' '/[0-9]\|\.\//{print $2}' | tee "$cache"
    fi | fzf "$@" | awk -F'/' '{print $2}' |
         sed -e 's/[]\[?\*\$]/\\&/g' | tr \\n \\0 |
         xargs -0rI{} find ~/.cache/torrents -type f -name '{}.torrent'
}
fzbt() {
    find . -maxdepth 3 -iname '*.torrent' | fzf \
        --preview 'aria2c -S {}' --preview-window 'border-sharp'
}
alacritty_theme_switcher() {
    local config themes
    config=~/.config/alacritty/alacritty.yml
    themes=~/.config/alacritty/themes
    cp -v "$config" "${config}.bkp"
    # shellcheck disable=SC2317
    pv() {
        config=~/.config/alacritty/alacritty.yml
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
    local cache=/tmp/.dlbkp
    target=${1:-.}
    if ! [ -e "$cache" ];then
        rclone lsf gdrive:backups | sort -V > "$cache"
    fi

    dl() {
        for i in "$@";do
            rclone copy -P gdrive:backups/"$i" "$target"
        done
    }
    export -f dl
    while read -r i;do
        [ -n "$i" ] && dl "$i" 
    done < <(fzf --height 20 -e -m --bind 'ctrl-d:execute(dl {+})' < "$cache")
    unset dl
}
fzopen() {
    fzf --bind 'enter:execute-silent(xdg-open {} & disown)'
}
fzpac() { 
    pacman "${@:--Qqe}" | fzf -m --header '^r ^s ^d' \
        --preview='pacman -Qi {}' --preview-window '70%' \
        --bind 'enter:reload(yay -Ssq {q})' \
        --bind 'ctrl-r:execute(sudo pacman -Rs {+})+reload(pacman -Qqe)' \
        --bind 'ctrl-s:execute(yay -Syu {+})' \
        --bind 'ctrl-d:execute(sudo downgrade {+})'
}
fzman() {
    # shellcheck disable=SC2016
    man -P cat "$1" 2>/dev/null | grep '^[A-Z]' |
        sed -e '1d' -e '$ d' | fzf |
        sed -e 's/[]\[?\*\$()]/\\\\&/g' |
        xargs -rI{} man -P 'less -p"^{}"' "$1"
}
