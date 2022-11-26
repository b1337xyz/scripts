#!/usr/bin/env python3
from utils import *
from sys import argv
import xmlrpc.client

sleep(2)
gid = argv[1]
s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')
torrent = s.aria2.tellStatus(gid)
torrent_name = get_torrent_name(torrent)
status = torrent['status']
size = get_psize(int(torrent["totalLength"]))

if torrent_name.startswith('[METADATA]') and status == 'complete':
    notify(f'aria2 - {status}', torrent_name)
    torrent_file = os.path.join(
        torrent['dir'],
        torrent['infoHash'] + '.torrent'
    )
    if os.path.exists(torrent_file):
        mv(torrent_file, CACHE)
        s.aria2.removeDownloadResult(gid)
elif status == 'complete':
    notify(f"aria2 - {status}", torrent_name, f'Size: {size}')
    path = os.path.join(torrent['dir'], torrent_name)
    if os.path.exists(path):
        mv(path, DL_DIR)
    s.aria2.removeDownloadResult(torrent['gid'])
else:
    notify(f"aria2 - {status}", torrent_name, f'Size: {size}')
