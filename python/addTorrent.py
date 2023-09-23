#!/usr/bin/env python3
from argparse import ArgumentParser
from xmlrpc.client import ServerProxy, Binary
from shutil import move
import subprocess as sp
import os
import re

MAX_SIZE = 2000000  # 2 MB
CACHE = os.path.expanduser('~/.cache/torrents')


def get_magnet(file):
    out = sp.run(['aria2c', '-S', file], stdout=sp.PIPE).stdout.decode()
    return re.search(r'magnet:\?[^\s]+', out).group(1)


def main():
    parser = ArgumentParser()
    parser.add_argument('-p', '--port', type=int, default=6800)
    parser.add_argument('torrent')
    args = parser.parse_args()
    aria2 = ServerProxy(f'http://127.0.0.1:{args.port}/rpc').aria2
    torrent = args.torrent

    if os.path.getsize(torrent) < MAX_SIZE:
        with open(torrent, 'rb') as f:
            aria2.addTorrent(Binary(f.read()))
    else:
        magnet = get_magnet(torrent)
        aria2.addUri([magnet])

    if os.path.isdir(CACHE):
        try:
            move(torrent, CACHE)
        except Exception as err:
            print(err)


if __name__ == '__main__':
    main()
