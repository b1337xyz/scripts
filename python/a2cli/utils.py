#!/usr/bin/env python3
from urllib.parse import unquote
import subprocess as sp
import shutil
import logging
import os
import re

HOME = os.getenv('HOME')
DL_DIR = os.path.join(HOME, 'Downloads')
TEMP_DIR = os.path.join(DL_DIR, '.torrents')
CACHE = os.path.join(HOME, '.cache/torrents')
ROOT = os.path.dirname(os.path.realpath(__file__))
LOG = os.path.join(ROOT, 'log')
MAX = 200
MAX_SIZE = 2000 * 1000  # 2 MB
FZF_ARGS = [
    '-m',
]


logging.basicConfig(
    filename=LOG,
    encoding='utf-8',
    filemode='a',
    level=logging.INFO,
    format='%(asctime)s:%(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)


def parse_arguments():
    from optparse import OptionParser
    usage = 'Usage: %prog [options] [FILE | URI]'
    parser = OptionParser(usage=usage)
    parser.add_option('--fzf', action='store_true')
    parser.add_option('-w', '--watch', action='store_true')
    parser.add_option('--port', type='string', default='6800')
    parser.add_option('-l', '--list', action='store_true',
                      help='list all downloads')
    parser.add_option('-r', '--remove', action='store_true',
                      help='remove chosen download')
    parser.add_option('-p', '--pause', action='store_true',
                      help='pause chosen download')
    parser.add_option('-u', '--unpause', action='store_true',
                      help='unpause chosen download')
    parser.add_option('--pause-all', action='store_true',
                      help='pause all downloads')
    parser.add_option('--unpause-all', action='store_true',
                      help='unpause all downloads')
    parser.add_option('--remove-all', action='store_true',
                      help='remove all downloads')
    parser.add_option('--remove-metadata', action='store_true',
                      help='remove all METADATA')
    parser.add_option('--top', action='store_true',
                      help='move a download to the top of the queue')
    parser.add_option('--status', type='string',
                      help='active complete error paused removed waiting')
    parser.add_option('--gid', type='string',
                      help='return a JSON of given GID')
    parser.add_option('--show-gid', action='store_true',
                      help='show gid')
    parser.add_option('--seed', action='store_true',
                      help='sets seed-time=0.0')
    parser.add_option('-m', '--max-downloads', type='int', metavar='[0-9]+',
                      help='max concurrent downloads')
    parser.add_option('--download-limit', type='string', metavar='<SPEED>',
                      help='overall download speed limit')
    parser.add_option('--upload-limit', type='string', metavar='<SPEED>',
                      help='overall upload speed limit')
    parser.add_option('-y', '--yes', action='store_true',
                      help='don\'t ask')
    parser.add_option('-s', '--save', action='store_true', help='save torrent')
    parser.add_option('--list-gids', action='store_true')
    parser.add_option('--purge', action='store_true')

    return parser.parse_args()


def yes():
    return input('Are you sure? [y/N] ').strip().lower() in ['y', 'yes']


def mv(src, dst):
    logging.info(f"mv '{src}' > '{dst}'")
    try:
        shutil.move(src, dst)
    except Exception as err:
        logging.error(err)


def notify(title, msg, icon='emblem-downloads'):
    try:
        sp.Popen(['notify-send', '-i', icon, title, msg])
    except Exception:
        pass


def is_uri(string: str) -> bool:
    return isinstance(re.match(r'\w+:(:?\/?\/?)[^\s]+', string), re.Match)


def is_torrent(file):
    cmd = ['file', '-Lbi', file]
    out = sp.run(cmd, stdout=sp.PIPE).stdout.decode()
    return 'bittorrent' in out or 'octet-stream' in out


def get_magnet(file):
    out = sp.run(['aria2c', '-S', file], stdout=sp.PIPE).stdout.decode()
    return re.search(r'magnet:\?[^\s]+', out).group(1)


def get_psize(size):
    psize = f"{size} B"
    for i in 'KMGTP':
        if size < 1000:
            break
        size /= 1000
        psize = f"{size:.2f} {i}"
    return psize


def get_name(info):
    try:
        return info['bittorrent']['info']['name']
    except KeyError:
        pass

    path = info['files'][0]['path']
    if path:
        return path.split('/')[-1]

    try:
        return unquote(info['files'][0]['uris'][0]['uri'].split('/')[-1])
    except Exception as err:
        return info['gid']


def fzf(args):
    proc = sp.Popen(["fzf"] + FZF_ARGS, stdin=sp.PIPE, stdout=sp.PIPE,
                    universal_newlines=True)
    out = proc.communicate('\n'.join(args))
    if proc.returncode != 0:
        exit(proc.returncode)
    return [i for i in out[0].split('\n') if i]
