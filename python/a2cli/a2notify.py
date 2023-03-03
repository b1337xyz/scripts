#!/usr/bin/env python3
from urllib.request import Request, urlopen
from sys import argv, exit
from time import sleep
from shutil import move
import logging
import subprocess as sp
import json
import os

HOST = 'http://localhost:6800/jsonrpc'
HOME = os.getenv('HOME')
DL_DIR = os.path.join(HOME, 'Downloads')
TEMP_DIR = os.path.join(DL_DIR, '.torrents')
CACHE = os.path.join(HOME, '.cache/torrents')
ROOT = os.path.dirname(os.path.realpath(__file__))
LOG = os.path.join(ROOT, 'log')

logging.basicConfig(
    filename=LOG,
    encoding='utf-8',
    filemode='a',
    level=logging.INFO,
    format='%(asctime)s:%(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)


def request(method, params):
    sleep(1)
    jsonreq = json.dumps({
        'jsonrpc': '2.0',
        'id': 'test',
        'method': f'aria2.{method}',
        'params': [params]
    }).encode('utf-8')
    r = Request(HOST)
    # r.add_header('Content-Length', len(jsonreq))
    # r.add_header('Content-Type', 'application/json; charset=utf-8')
    # r.add_header('Accept', 'application/json')
    try:
        with urlopen(r, jsonreq) as data:
            return json.loads(data.read().decode('utf-8'))["result"]
    except Exception as err:
        logging.error(str(err))


def get_name(info):
    try:
        return info['bittorrent']['info']['name']
    except KeyError:
        return info['files'][0]['path']


def get_torrent_file(info):
    try:
        infohash = info['infoHash']
        return os.path.join(_dir, f'{infohash}.torrent')
    except KeyError:  # not a torrent
        return ''


def get_psize(size):
    psize = f"{size} B"
    for i in 'KMGTP':
        if size < 1000:
            break
        size /= 1000
        psize = f"{size:.2f} {i}"
    return psize


def mv(src, dst):
    try:
        move(src, dst)
    except Exception:
        pass


def notify(title, msg, icon='emblem-downloads'):
    try:
        sp.Popen(['notify-send', '-i', icon, f'Aria2 - {title}', msg],
                 stderr=sp.DEVNULL)
    except Exception:
        pass


def on_complete():
    request('removeDownloadResult', gid)
    if is_metadata:
        if os.path.exists(torrent_file):
            mv(torrent_file, CACHE)
        notify(f'{status}', name)
    else:
        if os.path.exists(path) and _dir == TEMP_DIR:
            mv(path, DL_DIR)
        notify(f"{status}", f'{name}\nSize: {size}')


if __name__ == '__main__':
    # request('tellStopped', [0, 10])
    gid = argv[1]
    info = request('tellStatus', gid)
    if not info:
        exit(0)     
    name = get_name(info)
    _dir = info['dir']
    path = os.path.join(_dir, name)
    status = info['status']
    size = get_psize(int(info["totalLength"]))
    is_metadata = name.startswith('[METADATA]')
    torrent_file = get_torrent_file(info)

    match status:
        case 'complete':
            on_complete()
        case 'error':
            notify(f"{status}", name, icon='dialog-error')
        case _:
            notify(f"{status}", f'{name}\nSize: {size}')