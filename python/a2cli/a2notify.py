#!/usr/bin/env python3
from urllib.request import Request, urlopen
from urllib.parse import unquote
from sys import argv
from shutil import move
import subprocess as sp
import json
import os
import logging

HOST = 'http://127.0.0.1:6800/jsonrpc'
CACHE = os.path.expanduser('~/.cache/torrents')
LOG = os.path.expanduser('~/.cache/a2notify.log')

logging.basicConfig(level=logging.INFO,
                    filename=LOG,
                    filemode='a',
                    format='%(asctime)s:%(levelname)s: %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')

config = dict()
for file in [os.path.expanduser('~/.config/aria2/aria2.conf'),
             os.path.expanduser('~/.aria2/aria2.conf')]:

    if os.path.isfile(file):
        with open(file, 'r') as f:
            for line in f.readlines():
                if line.startswith('#') or '=' not in line:
                    continue

                k, v = line.strip().split('=', maxsplit=1)
                config[k] = v

DL_DIR = os.path.expandvars(config.get('dir', os.getenv('XDG_DOWNLOAD_DIR',
                                                        '${HOME}/Downloads')))


def request(method, params):
    jsonreq = json.dumps({
        'jsonrpc': '2.0',
        'id': 'test',
        'method': f'aria2.{method}',
        'params': [params]
    }).encode('utf-8')
    r = Request(HOST)
    r.add_header('Content-Type', 'application/json; charset=utf-8')
    r.add_header('Accept', 'application/json')
    with urlopen(r, jsonreq) as data:
        return json.loads(data.read().decode('utf-8'))["result"]


def get_torrent_file(info):
    infohash = info.get('infoHash')
    file = os.path.join(Dir, f'{infohash}.torrent')
    return file if os.path.isfile(file) else f'{Dir}.torrent'


def get_psize(size):
    psize = f"{size} B"
    for i in 'KMGTP':
        if size < 1000:
            break
        size /= 1000
        psize = f"{size:.2f} {i}"
    return psize


def mv(src, dst):
    c = 1
    filename = os.path.basename(src)
    target = os.path.join(dst, filename)
    filename, ext = os.path.splitext(filename)
    while os.path.exists(target):
        new_filename = f'{filename} ({c}){ext}'
        target = os.path.join(dst, new_filename)
        c += 1

    try:
        logging.info(f'"{src}" -> "{target}"')
        move(src, target)
    except Exception as err:
        logging.error(f'{err}')


def notify(title, msg, icon='emblem-downloads'):
    try:
        sp.Popen([
            'notify-send', '-r', '1337', '-i', icon, f'[aria2] {title}', msg
        ], stderr=sp.DEVNULL)
    except Exception:
        pass


def on_complete():
    try:
        request('removeDownloadResult', gid)
    except Exception:
        pass

    if os.path.isfile(torrent_file):
        mv(torrent_file, CACHE)

    if is_metadata:
        logging.info(f'{name} is metadata')
        notify(status, name)
        return

    notify(status, f'{name}\nSize: {size}')
    if os.path.basename(Dir).startswith('.') and Dir.endswith('_tempdir'):
        files = os.listdir(Dir)
        if any(f.endswith('.aria2') for f in files):
            return

        for f in files:
            path = os.path.join(Dir, f)
            if f.endswith('.torrent'):
                mv(path, CACHE)
            else:
                mv(path, DL_DIR)

        try:
            os.rmdir(Dir)
            logging.info(f'{Dir} removed')
        except Exception as err:
            logging.error(f'{err}')


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


if __name__ == '__main__':
    gid = argv[1]
    info = request('tellStatus', gid)

    if int(info.get("totalLength", 0)) < 3:
        exit(0)

    if not os.path.isdir(CACHE):
        os.makedirs(CACHE)

    name = get_name(info)
    Dir = info['dir']
    status = info['status']
    size = get_psize(int(info["totalLength"]))
    is_metadata = name.startswith('[METADATA]')
    torrent_file = get_torrent_file(info)

    if status == 'complete':
        on_complete()
    elif status == 'error':
        notify(status, name, icon='dialog-error')
    else:
        notify(status, f'{name}\nSize: {size}')
