#!/usr/bin/env python3
from utils import *
from sys import argv, exit
import xmlrpc.client

logging.info(' '.join(f"'{i}'" for i in argv[1:]))
sleep(3)
gid = argv[1]
s = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')
try:
    torrent = s.aria2.tellStatus(gid)
except Exception as err:
    # Probably not a torrent or not started from the rpc server
    exit(0)

torrent_name = get_torrent_name(torrent)
if not torrent_name:
    logging.warn(f'Ignoring torrent, {gid}')
    exit(0)

torrent_dir = torrent['dir']
status = torrent['status']
size = get_psize(int(torrent["totalLength"]))

if torrent_name.startswith('[METADATA]') and status == 'complete':
    notify(f'aria2 - {status}', torrent_name)
    torrent_file = os.path.join(torrent_dir, torrent['infoHash'] + '.torrent')
    if os.path.exists(torrent_file):
        mv(torrent_file, CACHE)
        s.aria2.removeDownloadResult(gid)
elif status == 'complete':
    notify(f"aria2 - {status}", torrent_name, f'Size: {size}')
    path = os.path.join(torrent_dir, torrent_name)
    if os.path.exists(path):
        mv(path, DL_DIR)
    s.aria2.removeDownloadResult(gid)
else:
    notify(f"aria2 - {status}", torrent_name, f'Size: {size}')
