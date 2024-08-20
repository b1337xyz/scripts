## *~/.scripts*
```
      /\         OS: Arch Linux x86_64
     /  \        WM: i3
    /\   \       Shell: bash 5.x.x, dash 0.5.12
   /      \      Python: 3.x.x
  /   ,,   \     
 /   |  |  -\    
/_-''    ''-_\   
```

#### Some of the software used
- shell 
  - [aria2](https://aria2.github.io/) - most scripts like [a2notify.py](python/a2notify.py) are hardcoded to use the rpc on localhost port 6800
  - [bat](https://github.com/sharkdp/bat)
  - [cksfv](http://zakalwe.fi/~shd/foss/cksfv)
  - [dash](http://gondor.apana.org.au/~herbert/dash/)
  - [devour](https://github.com/salman-abedin/devour)
  - [dmenu](https://tools.suckless.org/dmenu/) patched with [instant](https://tools.suckless.org/dmenu/patches/instant/) and [center](https://tools.suckless.org/dmenu/patches/center/)
  - [fzf](https://github.com/junegunn/fzf)
  - [jq](https://github.com/stedolan/jq)
  - [mediainfo](https://mediaarea.net/)
  - [nsxiv](https://github.com/nsxiv/nsxiv) patched with [dmenu-search](https://codeberg.org/nsxiv/nsxiv-extra/src/branch/master/patches/dmenu-search)
  - [ueberzug](https://github.com/b1337xyz/ueberzug)
  - [xclip](https://github.com/astrand/xclip)
  - [slop](https://github.com/naelstrof/slop)
  - [opusenc](https://wiki.xiph.org/Opus-tools)
  - [inotify-tools](https://github.com/inotify-tools/inotify-tools)
  - [xwallpaper](https://github.com/stoeckmann/xwallpaper)
  - [swaybg](https://github.com/swaywm/swaybg) *wayland*
  - [mpvpaper](https://github.com/GhostNaN/mpvpaper) *wayland*
  - [slurp](https://github.com/emersion/slurp) *wayland*
  - [grim](https://git.sr.ht/~emersion/grim) *wayland*
  - [rofi](https://github.com/DaveDavenport/rofi) *wayland*
  - [wf-recorder](https://github.com/ammen99/wf-recorder) *wayland*

- python  
  - [requests](https://requests.readthedocs.io/en/latest/)
  - [beautifulsoup4](https://www.crummy.com/software/BeautifulSoup/)
  - [i3ipc](https://github.com/altdesktop/i3ipc-python)
  - [thefuzz](https://github.com/seatgeek/thefuzz)
  - [google-api-python-client](https://github.com/googleapis/google-api-python-client) - [ytcli.py](https://github.com/b1337xyz/scripts/blob/main/python/ytcli.py)


#### Setup
```
sudo pacman -Syu --needed base-devel git python python-pip python-wheel \
    python-requests python-i3ipc python-google-api-python-client \
    aria2 bat cksfv dash fzf jq mediainfo ueberzug xclip xwallpaper \
    slop opus-tools nsxiv inotify-tools
```

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

```
cd /tmp
git clone https://github.com/salman-abedin/devour.git
cd devour && sudo make install
```
