#!/usr/bin/env python3
from urllib.request import Request, urlopen
from urllib.parse import unquote
from sys import argv
from time import sleep
from shutil import move
import subprocess as sp
import json
import os

HOST = 'http://127.0.0.1:6800/jsonrpc'
HOME = os.getenv('HOME')
DL_DIR = os.path.join(HOME, 'Downloads')
TEMP_DIR = os.path.join(DL_DIR, '.torrents')
CACHE = os.path.join(HOME, '.cache/torrents')


def request(method, params):
    jsonreq = json.dumps({
        'jsonrpc': '2.0',
        'id': 'test',
        'method': f'aria2.{method}',
        'params': [params]
    }).encode('utf-8')
    r = Request(HOST)
    r.add_header('Content-Length', len(jsonreq))
    r.add_header('Content-Type', 'application/json; charset=utf-8')
    r.add_header('Accept', 'application/json')
    with urlopen(r, jsonreq) as data:
        return json.loads(data.read().decode('utf-8'))["result"]


def get_name(info):
    try:
        return info['bittorrent']['info']['name']
    except KeyError:
        pass

    if (path := info['files'][0]['path']):
        return path.split('/')[-1]

    try:
        return unquote(info['files'][0]['uris'][0]['uri'].split('/')[-1])
    except Exception:
        return info['gid']


def get_torrent_file(info):
    infohash = info.get('infoHash')
    file = os.path.join(dir, f'{infohash}.torrent')
    return file if os.path.isfile(file) else f'{path}.torrent'


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
    except Exception as err:
        print(err)


def notify(title, msg, icon='emblem-downloads'):
    try:
        sp.Popen([
            'notify-send', '-r', '1337', '-i', icon, f'[aria2] {title}', msg
        ], stderr=sp.DEVNULL)
    except Exception:
        pass


def on_complete():
    request('removeDownloadResult', gid)
    if is_metadata:
        notify(status, name)
    else:
        notify(status, f'{name}\nSize: {size}')
        if os.path.exists(path) and dir == TEMP_DIR:
            mv(path, DL_DIR)

    if os.path.isfile(torrent_file):
        mv(torrent_file, CACHE)


if __name__ == '__main__':
    gid = argv[1]
    info = request('tellStatus', gid)
    if int(info.get("totalLength", 0)) < 2:
        exit(0)

    name = get_name(info)
    dir = info['dir']
    path = os.path.join(dir, name)
    status = info['status']
    size = get_psize(int(info["totalLength"]))
    is_metadata = name.startswith('[METADATA] ')
    torrent_file = get_torrent_file(info)

    match status:
        case 'complete':
            on_complete()
        case 'error':
            notify(f"{status}", name, icon='dialog-error')
        case _:
            notify(f"{status}", f'{name}\nSize: {size}')
