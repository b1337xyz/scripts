## *~/.scripts*
```
      /\         OS: Arch Linux x86_64
     /  \        WM: i3
    /\   \       Shell: bash 5.x.x, dash 0.5.11.5-1
   /      \      Python: 3.x.x
  /   ,,   \     
 /   |  |  -\    
/_-''    ''-_\   
```

## Dependencies
- shell 
  - [aria2](https://aria2.github.io/) - some scripts like [a2notify.py](https://github.com/b1337xyz/scripts/blob/main/python/a2notify.py) are hardcoded to use the rpc on localhost, port 6800
  - [bat](https://github.com/sharkdp/bat)
  - [cksfv](http://zakalwe.fi/~shd/foss/cksfv) - [crc32check](https://github.com/b1337xyz/scripts/blob/main/shell/functions.sh#L184) and [crc32rename](https://github.com/b1337xyz/scripts/blob/main/shell/functions.sh#L207)
  - [dash](http://gondor.apana.org.au/~herbert/dash/)
  - [devour](https://github.com/salman-abedin/devour)
  - [dmenu](https://tools.suckless.org/dmenu/) patched with [instant](https://tools.suckless.org/dmenu/patches/instant/) and [center](https://tools.suckless.org/dmenu/patches/center/)
  - [fzf](https://github.com/junegunn/fzf)
  - [jq](https://github.com/stedolan/jq)
  - [mediainfo](https://mediaarea.net/)
  - [nsxiv](https://github.com/nsxiv/nsxiv)
  - [ueberzug](https://github.com/b1337xyz/ueberzug)
  - [xclip](https://github.com/astrand/xclip)
  - [xwallpaper](https://github.com/stoeckmann/xwallpaper)
  - [slop](https://github.com/naelstrof/slop) - [ffrecord.sh -s](https://github.com/b1337xyz/scripts/blob/main/shell/ffmpeg/ffrecord.sh)
  - [opusenc](https://wiki.xiph.org/Opus-tools) - [flac2opus.sh](https://github.com/b1337xyz/scripts/blob/main/shell/ffmpeg/flac2opus.sh)
  - [inotify-tools](https://github.com/inotify-tools/inotify-tools)

- python  
  - [requests](https://requests.readthedocs.io/en/latest/)
  - [beautifulsoup4](https://www.crummy.com/software/BeautifulSoup/)
  - [i3ipc](https://github.com/altdesktop/i3ipc-python)
  - [thefuzz](https://github.com/seatgeek/thefuzz)
  - [google-api-python-client](https://github.com/googleapis/google-api-python-client) - [ytcli.py](https://github.com/b1337xyz/scripts/blob/main/python/ytcli.py)


## Install
Arch Linux
```
sudo pacman -Syu --needed base-devel git python python-pip python-wheel \
    python-requests python-i3ipc python-google-api-python-client \
    aria2 bat cksfv dash fzf jq mediainfo ueberzug xclip xwallpaper slop opus-tools nsxiv
```

Install and patch dmenu
```
cd /tmp
git clone https://git.suckless.org/dmenu
cd dmenu
wget https://tools.suckless.org/dmenu/patches/instant/dmenu-instant-4.7.diff
wget https://tools.suckless.org/dmenu/patches/center/dmenu-center-5.2.diff
patch -p1 < dmenu-instant-4.7.diff
patch -p1 < dmenu-center-5.2.diff
make && sudo make install
```

Install devour
```
cd /tmp
git clone https://github.com/salman-abedin/devour.git
cd devour && sudo make install
```

Install thefuzz
```
python3 -m pip install --user thefuzz --break-system-packages
```
