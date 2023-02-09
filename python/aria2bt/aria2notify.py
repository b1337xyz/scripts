#!/usr/bin/env python3
from utils import *
from sys import argv
from time import sleep
import xmlrpc.client

FIFO = '/tmp/aria2notify.fifo'


def torrent_handler(session, gid):
    sleep(3)
    torrent = session.aria2.tellStatus(gid)
    torrent_name = get_torrent_name(torrent)
    torrent_dir = torrent['dir']
    path = os.path.join(torrent_dir, torrent_name)
    status = torrent['status']
    size = get_psize(int(torrent["totalLength"]))
    is_metadata = torrent_name.startswith('[METADATA]')
    torrent_file = os.path.join(torrent_dir, torrent['infoHash'] + '.torrent')

    if status == 'complete':
        if is_metadata:
            notify(f'aria2 - {status}', torrent_name)
            if os.path.exists(torrent_file):
                mv(torrent_file, CACHE)
        else:
            notify(f"aria2 - {status}", f'{torrent_name}\nSize: {size}')
            if os.path.exists(path) and torrent_dir == TEMP_DIR:
                mv(path, DL_DIR)
        session.aria2.removeDownloadResult(gid)
    elif status == 'error':
        notify(f"aria2 - {status}", torrent_name, icon='dialog-error')
    else:
        notify(f"aria2 - {status}", f'{torrent_name}\nSize: {size}')


def main(gid):
    os.mkfifo(FIFO)
    session = xmlrpc.client.ServerProxy('http://localhost:6800/rpc')

    try:
        torrent_handler(session, gid)
    except Exception as err:
        logging.error(err)

    while os.path.exists(FIFO):
        with open(FIFO, 'r') as fifo:
            data = [i for i in fifo.read().split('\n') if i]
        if len(data) == 0:
            break

        for gid in data:
            try:
                torrent_handler(session, gid)
            except Exception as err:
                logging.error(f'{err}: {gid}')


if os.path.exists(FIFO):
    with open(FIFO, 'w') as fifo:
        fifo.write(f'{argv[1]}\n')  # write gid
else:
    try:
        main(argv[1])
    finally:
        os.remove(FIFO)
